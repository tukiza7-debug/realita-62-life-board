package id.realita62.lifeboard.engine

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import id.realita62.lifeboard.data.CardLibrary

/**
 * Orchestrates a full game: turn order, AI moves, autosave, game-over detection.
 * The orchestrator is the only class the UI talks to (besides CardResolver
 * for choice cards). It hides the engine / deck / movement wiring.
 */
class GameOrchestrator(
    val state: GameState,
    val balance: BalanceConfig = BalanceConfig.DEFAULT,
    val board: List<Tile> = BoardFactory.default(balance.boardSize),
    val cardLibrary: CardLibrary
) {
    val engine = GameEngine(balance, SeededRng(state.seed))
    val deck = CardDeck(engine, cardLibrary)
    val movement = Movement(engine, board)
    val resolver = CardResolver(engine)

    /** Returns true if the current player's turn is over (and the orchestrator
     *  should advance to the next player). */
    var currentTurnDone: Boolean = false
        private set

    /** Begin a new game with the given players (after education fork). */
    fun startGame() {
        state.turn = 0
        state.currentPlayerIdx = 0
        state.gameOver = false
    }

    /** Set the player's career at the start (after education path). */
    fun assignCareer(playerIdx: Int, career: Career) {
        state.players[playerIdx].career = career
    }

    fun setEducation(playerIdx: Int, path: EducationPath) {
        val p = state.players[playerIdx]
        p.education = path
        p.cash = path.startingCash
        p.uktDebt = path.uktDebt
    }

    /** Convenience: get the current player. */
    val currentPlayer: Player get() = state.players[state.currentPlayerIdx]

    /** Take a turn for the current player: roll dice, advance, resolve tile. */
    fun takeTurn(): TurnResult {
        val p = currentPlayer
        if (p.retired) {
            // Skip to next player
            advancePlayer()
            return TurnResult(emptyList(), turnDone = true, gameOver = state.gameOver)
        }

        if (p.skipsNextTurn) {
            p.skipsNextTurn = false
            advancePlayer()
            return TurnResult(listOf(GameEvent.SkipTurn(p.id, 1)), turnDone = true, gameOver = state.gameOver)
        }

        val ev = mutableListOf<GameEvent>()
        // 1. Roll dice and move.
        ev += movement.rollAndMove(state, state.currentPlayerIdx)
        // 2. Resolve tile.
        ev += resolveTile(p)
        // 3. End-of-lap effects (apply once per player per turn — the "lap" is
        //    modeled as one full trip around the board; here we apply once per
        //    turn for stability of cash flow).
        ev += engine.endOfLap(state, state.currentPlayerIdx)
        // 4. Reset good-luck draw counter at start of new lap for this player.
        if (p.position == 0) {
            state.goodLuckDrawsThisLap[state.currentPlayerIdx] = 0
        }

        state.log.addAll(ev)
        advancePlayer()
        return TurnResult(ev, turnDone = true, gameOver = state.gameOver)
    }

    private fun resolveTile(p: Player): List<GameEvent> {
        val tile = board[p.position]
        return when (tile.type) {
            TileType.PAYDAY -> engine.payday(state, p.id)
            TileType.EVENT -> {
                val card = deck.drawEvent()
                state.drawnEvents += card.id
                val drawEv = GameEvent.CardDrawn(p.id, card.id, isLuck = false)
                if (resolver.needsChoice(card)) {
                    // The UI will be told to show a choice dialog; we return the draw event
                    // and the UI will call applyChoiceAndContinue(card, choice) when ready.
                    pendingChoice = PendingChoice(p.id, card)
                    listOf(drawEv)
                } else {
                    listOf(drawEv) + resolver.resolveImmediate(state, p.id, card)
                }
            }
            TileType.LUCK -> {
                val card = deck.drawLuck(state, p.id)
                state.drawnLuck += card.id
                val drawEv = GameEvent.CardDrawn(p.id, card.id, isLuck = true)
                if (card.id.startsWith("GL") && resolver.needsChoice(card)) {
                    pendingChoice = PendingChoice(p.id, card)
                    listOf(drawEv)
                } else {
                    listOf(drawEv) + resolver.resolveImmediate(state, p.id, card)
                }
            }
            TileType.MARRIAGE -> {
                // Player will be prompted by UI to pick lavish vs modest.
                pendingMarriage = p.id
                listOf(GameEvent.Empty)
            }
            TileType.CHILD -> engine.addChild(state, p.id)
            TileType.ASSET_SHOP -> {
                pendingAssetShop = p.id
                listOf(GameEvent.Empty)
            }
            TileType.MAHAR_PARTAI_GATE -> {
                pendingMaharPartai = p.id
                listOf(GameEvent.Empty)
            }
            TileType.TENDER -> {
                // Tender tiles give Contractor a one-off bonus opportunity (already covered
                // by EVENT_MBG_TENDER card when drawn; here we just trigger a small income).
                if (p.career == Career.CONTRACTOR) {
                    p.cash += 2.0
                    listOf(GameEvent.CashDelta(p.id, 2.0, "Tender bonus"))
                } else emptyList()
            }
            TileType.RETIREMENT_FORK -> {
                pendingRetirement = p.id
                listOf(GameEvent.Empty)
            }
            TileType.START, TileType.EDUCATION_FORK, TileType.BLANK -> emptyList()
        }
    }

    // ---- Pending choices (UI reads these to show a dialog) ----------------
    var pendingChoice: PendingChoice? = null
        private set
    var pendingMarriage: Int? = null
        private set
    var pendingAssetShop: Int? = null
        private set
    var pendingMaharPartai: Int? = null
        private set
    var pendingRetirement: Int? = null
        private set

    fun applyChoiceAndContinue(card: CardDef, choice: String): List<GameEvent> {
        val pc = pendingChoice ?: return emptyList()
        val ev = resolver.applyChoice(state, pc.playerIdx, card, choice)
        state.log.addAll(ev)
        pendingChoice = null
        return ev
    }

    fun applyMarriage(lavish: Boolean): List<GameEvent> {
        val idx = pendingMarriage ?: return emptyList()
        val ev = engine.marry(state, idx, lavish)
        state.log.addAll(ev)
        pendingMarriage = null
        return ev
    }

    fun applyAssetPurchase(assetId: String): List<GameEvent> {
        val idx = pendingAssetShop ?: return emptyList()
        val result = engine.purchaseAsset(state, idx, assetId)
        return when (result) {
            is PurchaseResult.Ok -> {
                val ev = listOf(GameEvent.AssetPurchased(idx, result.asset.id, result.asset.name))
                state.log.addAll(ev)
                pendingAssetShop = null
                ev
            }
            is PurchaseResult.Failed -> listOf(GameEvent.Empty)
        }
    }

    fun applyMaharPartai(enter: Boolean, corrupt: Boolean = false): List<GameEvent> {
        val idx = pendingMaharPartai ?: return emptyList()
        val ev = if (enter) engine.enterPoliticianPath(state, idx, corrupt)
                 else listOf(GameEvent.HappinessDelta(idx, 2, "Declined politics"))
        state.log.addAll(ev)
        pendingMaharPartai = null
        return ev
    }

    fun applyRetirement(choice: RetirementChoice): List<GameEvent> {
        val idx = pendingRetirement ?: return emptyList()
        val ev = engine.retire(state, idx, choice)
        state.log.addAll(ev)
        pendingRetirement = null
        if (engine.isGameOver(state)) {
            state.gameOver = true
        }
        return ev
    }

    // ---------------------------------------------------------------------
    // Player advancement
    // ---------------------------------------------------------------------
    private fun advancePlayer() {
        val n = state.players.size
        var next = (state.currentPlayerIdx + 1) % n
        var guard = 0
        while (state.players[next].retired && guard < n) {
            next = (next + 1) % n
            guard += 1
        }
        state.currentPlayerIdx = next
        state.turn += 1
        currentTurnDone = true
    }

    // ---------------------------------------------------------------------
    // Save / load
    // ---------------------------------------------------------------------
    fun serialize(): String = JSON.encodeToString(GameState.serializer(), state)

    companion object {
        val JSON = Json {
            ignoreUnknownKeys = true
            encodeDefaults = true
            prettyPrint = false
            classDiscriminator = "_type"
        }

        fun load(serialized: String, library: CardLibrary, balance: BalanceConfig = BalanceConfig.DEFAULT): GameOrchestrator {
            val state = JSON.decodeFromString(GameState.serializer(), serialized)
            return GameOrchestrator(state, balance, BoardFactory.default(balance.boardSize), library)
        }
    }

    /** Simple AI: makes sensible choices for choice cards / marriage / assets. */
    fun aiMakeChoice(card: CardDef): String {
        // Simple heuristic: decline corrupt options if heat is high; accept cheap positives.
        return when (card.effect) {
            "EVENT_MBG_TENDER" -> "decline"
            "EVENT_PARTY_DOWRY_OFFER" -> "decline"
            "EVENT_PORK_BARREL" -> "clean"
            "EVENT_PRIVATE_SCHOOL_FEE" -> if (currentPlayer.cash >= 5.0) "private" else "public"
            "EVENT_RELATIVE_NEEDS_HELP" -> if (currentPlayer.cash >= 2.5) "help" else "refuse"
            "EVENT_GAMBLING_AD" -> "ignore"
            "EVENT_SIDE_BUSINESS" -> if (currentPlayer.cash >= 4.0) "start" else "decline"
            "EVENT_BRIBE_OFFER" -> "decline"
            "EVENT_VOTER_HANDOUT" -> "accept"
            else -> ""
        }
    }

    fun aiChooseRetirement(): RetirementChoice {
        val p = currentPlayer
        return when {
            p.cash + p.netAssets() >= 60.0 -> RetirementChoice.ELITE_MENTENG
            p.cash + p.netAssets() >= 25.0 -> RetirementChoice.ISLAND_BALI
            else -> RetirementChoice.KAMPUNG_JOGJA
        }
    }
}

data class PendingChoice(val playerIdx: Int, val card: CardDef)

data class TurnResult(
    val events: List<GameEvent>,
    val turnDone: Boolean,
    val gameOver: Boolean
)
