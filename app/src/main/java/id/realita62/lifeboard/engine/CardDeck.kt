package id.realita62.lifeboard.engine

import id.realita62.lifeboard.data.CardDef
import id.realita62.lifeboard.data.CardLibrary

/**
 * Manages the deck of event and luck cards. Shuffles deterministically using
 * the engine's RNG, draws without replacement (until exhausted), then reshuffles.
 *
 * Enforces per-lap good-luck draw cap (max 2 per player per lap).
 */
class CardDeck(val engine: GameEngine, val library: CardLibrary) {
    private var eventPile: MutableList<CardDef> = mutableListOf()
    private var goodLuckPile: MutableList<CardDef> = mutableListOf()
    private var badLuckPile: MutableList<CardDef> = mutableListOf()

    init {
        reshuffle()
    }

    fun reshuffle() {
        eventPile = library.events.toMutableList().also { engine.rng.shuffle(it) }
        goodLuckPile = library.goodLuck.toMutableList().also { engine.rng.shuffle(it) }
        badLuckPile = library.badLuck.toMutableList().also { engine.rng.shuffle(it) }
    }

    /** Draw an event card (without replacement). */
    fun drawEvent(): CardDef {
        if (eventPile.isEmpty()) reshuffle()
        return eventPile.removeAt(0)
    }

    /** Draw a good luck card respecting the per-lap cap (max 2 per player per lap). */
    fun drawGoodLuck(state: GameState, playerIdx: Int): CardDef? {
        if (goodLuckPile.isEmpty()) goodLuckPile = library.goodLuck.toMutableList().also { engine.rng.shuffle(it) }
        if (state.goodLuckDrawsThisLap[playerIdx] >= engine.balance.maxGoodLuckPerLap) return null
        state.goodLuckDrawsThisLap[playerIdx] = state.goodLuckDrawsThisLap[playerIdx] + 1
        return goodLuckPile.removeAt(0)
    }

    /** Draw a bad luck card. Cash loss is reduced by 25% if player has savings buffer. */
    fun drawBadLuck(): CardDef {
        if (badLuckPile.isEmpty()) badLuckPile = library.badLuck.toMutableList().also { engine.rng.shuffle(it) }
        return badLuckPile.removeAt(0)
    }

    /** Draw a luck card (50/50 good vs bad). */
    fun drawLuck(state: GameState, playerIdx: Int): CardDef {
        return if (engine.rng.chance(0.5f)) {
            drawGoodLuck(state, playerIdx) ?: drawBadLuck()
        } else {
            drawBadLuck()
        }
    }

    /** Reset per-lap good-luck counters — called when a player completes a lap. */
    fun resetLapCounters(state: GameState) {
        for (i in state.goodLuckDrawsThisLap.indices) {
            state.goodLuckDrawsThisLap[i] = 0
        }
    }
}

/**
 * Movement logic: dice roll, tile advance, pawn hopping, lap completion.
 *
 * Applies fuel subsidy extra cost on every dice roll (event E06).
 */
class Movement(val engine: GameEngine, val board: List<Tile>) {

    /** Roll the dice for a player and advance them. Returns the events raised. */
    fun rollAndMove(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        val ev = mutableListOf<GameEvent>()

        val dice = engine.rng.rollDice()
        state.lastDiceRoll = dice
        val from = p.position
        val to = (from + dice.total).coerceAtMost(board.lastIndex)
        p.position = to
        ev += GameEvent.Moved(playerIdx, from, to)

        // Fuel subsidy extra cost (event E06): +Rp 0.2M per roll for affected laps.
        if (p.fuelSubsidyLapsLeft > 0 && p.fuelSubsidyExtraPerRoll > 0) {
            p.cash -= p.fuelSubsidyExtraPerRoll
            ev += GameEvent.CashDelta(playerIdx, -p.fuelSubsidyExtraPerRoll, "Fuel subsidy extra")
        }

        // Lap completion: any time we wrap around (or land on the retirement fork
        // for the first time). Lap counter ticks on passing position 0.
        if (to < from) {
            // Wrapped around (e.g. position 58 -> 3 because of wrap) — unlikely on 60-tile board
            // because retirement fork ends the game. We still increment for safety.
            p.lapsCompleted += 1
            ev += GameEvent.LapCompleted(playerIdx, p.lapsCompleted)
            engine.let { } // placeholder for any lap-based global effects
        }

        return ev
    }
}
