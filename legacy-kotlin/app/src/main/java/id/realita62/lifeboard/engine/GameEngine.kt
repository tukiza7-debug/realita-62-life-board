package id.realita62.lifeboard.engine

import kotlinx.serialization.Serializable

/**
 * The deterministic rules engine. Pure logic — no Android imports.
 * All randomness goes through the injected [SeededRng]. Same seed → same game.
 *
 * The engine consumes [BalanceConfig] for tunables and produces
 * [GameEvent] entries that the UI renders as animations / log entries.
 * No side effects, no I/O — every state change is a copy of [GameState].
 */
class GameEngine(
    val balance: BalanceConfig = BalanceConfig.DEFAULT,
    val rng: SeededRng
) {
    // ---------------------------------------------------------------------
    // PAYDAY
    // ---------------------------------------------------------------------

    /**
     * Resolve a payday tile. Applies gross payday, TAPERA (PNS/SCBD), and
     * sets skipsNextPayday to false (the player has now consumed the skip).
     *
     * Returns the events raised.
     */
    fun payday(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        val events = mutableListOf<GameEvent>()

        if (p.skipsNextPayday) {
            p.skipsNextPayday = false
            events += GameEvent.PaydaySkipped(playerIdx)
            return events
        }

        val career = p.career ?: return events
        var gross = career.grossPayday

        // Side business income (event E21)
        if (p.sideBusinessLapsLeft > 0) {
            gross += p.sideBusinessIncomePerLap
            events += GameEvent.SideBusinessPaid(playerIdx, p.sideBusinessIncomePerLap)
        }

        // TAPERA deduction for PNS / SCBD
        var taperaDeduction = 0.0
        if (career == Career.PNS || career == Career.SCBD_EMPLOYEE) {
            taperaDeduction = gross * balance.taperaPct.toDouble()
            gross -= taperaDeduction
        }

        p.cash += gross

        events += GameEvent.Payday(playerIdx, career, gross, taperaDeduction)
        return events
    }

    // ---------------------------------------------------------------------
    // END-OF-LAP RESOLUTION (interest, living cost, fuel-subsidy timer)
    // ---------------------------------------------------------------------

    /** Apply per-lap costs: living cost, UKT/KPR/Pinjol interest, fuel subsidy,
     *  side-business/lord-rent/cheap-rent timers. */
    fun endOfLap(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        val events = mutableListOf<GameEvent>()

        // 1. Living cost (with children + cheap-rent discount + landlord extra).
        val living = p.livingCostThisLap(balance.baseLivingCostPerLap, balance.perChildLivingCost)
        if (living > 0) {
            p.cash -= living
            events += GameEvent.LivingCost(playerIdx, living)
        }

        // 2. UKT interest (2% per lap).
        if (p.uktDebt > 0.001) {
            val interest = p.uktDebt * balance.uktInterestPerLapPct.toDouble()
            p.uktDebt += interest
            events += GameEvent.UktInterest(playerIdx, interest)
        }

        // 3. KPR interest per asset (3% base, may be boosted by event E17).
        for (asset in p.assets) {
            if (!asset.hasKpr) continue
            val rate = balance.kprInterestBasePerLapPct +
                (if (asset.kprInterestBoostLapsLeft > 0) 0.01f else 0.0f)
            val interest = asset.remainingKpr * rate.toDouble()
            asset.remainingKpr = (asset.remainingKpr + interest).coerceAtLeast(0.0)
            if (asset.kprInterestBoostLapsLeft > 0) {
                asset.kprInterestBoostLapsLeft -= 1
            }
            events += GameEvent.KprInterest(playerIdx, asset.id, interest)
        }

        // 4. Pinjol interest (15% per lap) — precomputed for HUD.
        if (p.pinjolDebt > 0.001) {
            val interest = p.pinjolDebt * balance.pinjolInterestPerLapPct.toDouble()
            p.pinjolDebt += interest
            p.pinjolInterestNextLap = p.pinjolDebt * balance.pinjolInterestPerLapPct.toDouble()
            events += GameEvent.PinjolInterest(playerIdx, interest)
        } else {
            p.pinjolInterestNextLap = 0.0
        }

        // 5. Fuel subsidy (event E06) — applied per dice roll, but timer ticks per lap.
        if (p.fuelSubsidyLapsLeft > 0) {
            p.fuelSubsidyLapsLeft -= 1
            if (p.fuelSubsidyLapsLeft == 0) {
                p.fuelSubsidyExtraPerRoll = 0.0
                events += GameEvent.FuelSubsidyEnded(playerIdx)
            }
        }

        // 6. Side business timer.
        if (p.sideBusinessLapsLeft > 0) {
            p.sideBusinessLapsLeft -= 1
            if (p.sideBusinessLapsLeft == 0) {
                p.sideBusinessIncomePerLap = 0.0
                events += GameEvent.SideBusinessEnded(playerIdx)
            }
        }

        // 7. Landlord extra-rent timer (BL07).
        if (p.landlordRentExtraLapsLeft > 0) {
            p.landlordRentExtraLapsLeft -= 1
            if (p.landlordRentExtraLapsLeft == 0) {
                p.landlordRentExtraPerLap = 0.0
                events += GameEvent.LandlordRentEnded(playerIdx)
            }
        }

        // 8. Cheap-rent discount timer (GL14).
        if (p.cheapRentDiscountLapsLeft > 0) {
            p.cheapRentDiscountLapsLeft -= 1
            if (p.cheapRentDiscountLapsLeft == 0) {
                p.cheapRentDiscountPct = 0.0f
                events += GameEvent.CheapRentEnded(playerIdx)
            }
        }

        p.lapsCompleted += 1

        return events
    }

    // ---------------------------------------------------------------------
    // ASSET PURCHASE (PPN 12% + KPR)
    // ---------------------------------------------------------------------

    /** Purchase an asset: 20% down payment (with PPN 12% on the price),
     *  80% as KPR on the player's balance sheet. */
    fun purchaseAsset(state: GameState, playerIdx: Int, assetId: String): PurchaseResult {
        val p = state.players[playerIdx]
        val def = state.assetCatalogue.items.firstOrNull { it.id == assetId }
            ?: return PurchaseResult.Failed("Unknown asset $assetId")

        val priceWithPpn = def.price * (1.0 + balance.ppnPct.toDouble())
        val down = priceWithPpn * 0.20
        if (p.cash < down) {
            return PurchaseResult.Failed("Not enough cash for down payment (Rp ${down}M)")
        }
        p.cash -= down
        val kpr = priceWithPpn * 0.80
        val asset = Asset(
            id = def.id,
            name = def.nameEn,
            price = def.price,
            remainingKpr = kpr,
            kprInterestBase = def.kprInterestBasePerLapPct
        )
        p.assets += asset
        return PurchaseResult.Ok(down, kpr, asset)
    }

    // ---------------------------------------------------------------------
    // CORRUPTION (Politician Corrupt path)
    // ---------------------------------------------------------------------

    /** Politician Corrupt: steal project funds (fast cash, +heat). */
    fun stealProjectFunds(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        if (p.career != Career.POLITICIAN_CORRUPT) return emptyList()
        val amount = balance.enterCorruptTheftPerLap
        p.cash += amount
        p.corruptionHeat += balance.enterCorruptHeatPerTheft
        p.corruptFlagEver = true
        return listOf(GameEvent.StoleProjectFunds(playerIdx, amount, p.corruptionHeat))
    }

    /** KPK sting check. Called whenever the engine decides to roll for it
     *  (e.g. landing on event tile while corrupt). */
    fun rollKpkSting(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        if (p.career != Career.POLITICIAN_CORRUPT) return emptyList()
        val chance = (p.corruptionHeat * balance.kpkStingChancePerHeatPct).coerceAtMost(1.0f)
        if (!rng.chance(chance)) {
            // Clean politician gets a small H bonus instead
            return listOf(GameEvent.KpkStingMiss(playerIdx))
        }
        // Caught!
        val cashLoss = p.cash * balance.kpkStingCaughtCashLossPct.toDouble()
        p.cash -= cashLoss
        p.happiness -= balance.kpkStingCaughtHeatLoss
        p.skipsNextTurn = true
        // lose 2 turns total: skipsNextTurn + skipTurnLoss token
        p.tokens.skipTurnLoss = p.tokens.skipTurnLoss + 1
        p.corruptionHeat = (p.corruptionHeat / 2).coerceAtLeast(0)
        return listOf(GameEvent.KpkStingCaught(playerIdx, cashLoss))
    }

    // ---------------------------------------------------------------------
    // SCORING (end of game)
    // ---------------------------------------------------------------------

    /** Final score for a retired player.
     *  score = netAssets + cash + (H * 0.5M) + legacyBonus
     *  Corrupt route with final H < 0 → score halved. */
    fun finalScore(p: Player): Rp {
        val legacyBonus = computeLegacyBonus(p)
        var score = p.netAssets() + p.cash.coerceAtLeast(0.0) +
            (p.happiness * balance.happinessValueInScore.toDouble()) +
            legacyBonus
        if (p.corruptFlagEver && p.happiness < balance.corruptRouteFinalHappinessThreshold) {
            score = score / balance.corruptRouteFinalScoreDivider.toDouble()
        }
        return score
    }

    /** Dynasty mechanic: each funded child +Rp 3M, each unfunded +Rp 0.5M.
     *  Nepotism perk reduces funded legacy bonus by 50%. */
    private fun computeLegacyBonus(p: Player): Rp {
        var funded = 0.0
        var unfunded = 0.0
        for (c in p.children) {
            if (c.isFunded) funded += balance.legacyPerFundedChild
            else unfunded += balance.legacyPerUnfundedChild
        }
        if (p.usedNepotismPerk) funded *= 0.5
        return funded + unfunded
    }

    /** Warga Teladan +62 (Model Citizen) — no corruption, no Pinjol at end,
     *  positive H, retires in Jogja or Bali. */
    fun isWargaTeladan(p: Player): Boolean {
        return !p.corruptFlagEver &&
            !p.hasPinjol &&
            p.happiness > 0 &&
            (p.retirement == RetirementChoice.KAMPUNG_JOGJA || p.retirement == RetirementChoice.ISLAND_BALI)
    }

    // ---------------------------------------------------------------------
    // FAMILY (marriage, children)
    // ---------------------------------------------------------------------

    fun marry(state: GameState, playerIdx: Int, lavish: Boolean): List<GameEvent> {
        val p = state.players[playerIdx]
        return if (lavish) {
            p.cash -= balance.lavishWeddingCost
            // Lavish: if cash goes negative, the difference becomes Pinjol (debt for social image).
            if (p.cash < 0) {
                p.pinjolDebt += -p.cash
                p.cash = 0.0
            }
            p.maritalStatus = MaritalStatus.MARRIED_LAVISH
            p.happiness += balance.lavishWeddingHappiness
            listOf(GameEvent.Married(playerIdx, lavish = true, balance.lavishWeddingCost, balance.lavishWeddingHappiness))
        } else {
            p.cash -= balance.modestWeddingCost
            p.maritalStatus = MaritalStatus.MARRIED_MODEST
            p.happiness += balance.modestWeddingHappiness
            listOf(GameEvent.Married(playerIdx, lavish = false, balance.modestWeddingCost, balance.modestWeddingHappiness))
        }
    }

    fun addChild(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        val c = Child(id = "c-${p.children.size + 1}-${state.turn}")
        p.children += c
        return listOf(GameEvent.ChildBorn(playerIdx, c.id))
    }

    /** Fund a child's education (pay school fees for this lap).
     *  If private school chosen, costs more but counts as funded for legacy. */
    fun fundChildSchool(state: GameState, playerIdx: Int, childIdx: Int, private: Boolean): List<GameEvent> {
        val p = state.players[playerIdx]
        if (childIdx !in p.children.indices) return emptyList()
        val c = p.children[childIdx]
        val cost = if (private) 5.0 else 1.5
        p.cash -= cost
        // Update child copy
        p.children[childIdx] = c.copy(isFunded = true, isPrivateSchool = private)
        return listOf(GameEvent.SchoolFunded(playerIdx, childIdx, private, cost))
    }

    // ---------------------------------------------------------------------
    // ENTER POLITICIAN PATH (Mahar Partai gate)
    // ---------------------------------------------------------------------

    fun enterPoliticianPath(state: GameState, playerIdx: Int, corrupt: Boolean): List<GameEvent> {
        val p = state.players[playerIdx]
        if (p.cash < balance.partyDowry) {
            return listOf(GameEvent.PoliticianEntryFailed(playerIdx, "Not enough cash"))
        }
        p.cash -= balance.partyDowry
        p.career = if (corrupt) Career.POLITICIAN_CORRUPT else Career.POLITICIAN_CLEAN
        p.route = if (corrupt) Route.CORRUPT else Route.CLEAN
        if (corrupt) p.corruptFlagEver = true
        return listOf(GameEvent.EnteredPoliticianPath(playerIdx, corrupt, balance.partyDowry))
    }

    /** Nepotism perk (politician-only): quick cash, costs H, halves legacy bonus. */
    fun nepotismPerk(state: GameState, playerIdx: Int): List<GameEvent> {
        val p = state.players[playerIdx]
        if (p.career?.isPolitician != true) return emptyList()
        val gain = 4.0
        p.cash += gain
        p.happiness -= 6
        p.usedNepotismPerk = true
        return listOf(GameEvent.NepotismPerk(playerIdx, gain))
    }

    // ---------------------------------------------------------------------
    // RETIREMENT
    // ---------------------------------------------------------------------

    fun retire(state: GameState, playerIdx: Int, choice: RetirementChoice): List<GameEvent> {
        val p = state.players[playerIdx]
        p.retired = true
        p.retirement = choice
        val score = finalScore(p)
        return listOf(GameEvent.Retired(playerIdx, choice, score, isWargaTeladan(p)))
    }

    fun isGameOver(state: GameState): Boolean = state.players.all { it.retired }

    // ---------------------------------------------------------------------
    // CHILD RNG
    // ---------------------------------------------------------------------
    fun forkCardRng(state: GameState): SeededRng = rng.fork(state.turn.toLong() * 31L + 7L)
}

// ---------------------------------------------------------------------
// RESULT TYPES
// ---------------------------------------------------------------------

sealed class PurchaseResult {
    data class Ok(val downPayment: Rp, val kprPrincipal: Rp, val asset: Asset) : PurchaseResult()
    data class Failed(val reason: String) : PurchaseResult()
}

// ---------------------------------------------------------------------
// GAME STATE
// ---------------------------------------------------------------------

@Serializable
data class GameState(
    val seed: Long,
    val players: MutableList<Player>,
    var turn: Int = 0,
    var currentPlayerIdx: Int = 0,
    val log: MutableList<GameEvent> = mutableListOf(),
    var assetCatalogue: AssetCatalogue = AssetCatalogue(),
    val drawnEvents: MutableList<String> = mutableListOf(),
    val drawnLuck: MutableList<String> = mutableListOf(),
    val goodLuckDrawsThisLap: IntArray = intArrayOf(0, 0, 0, 0),
    var gameOver: Boolean = false,
    var lastDiceRoll: DiceRoll? = null
)

// ---------------------------------------------------------------------
// EVENT STREAM (consumed by UI + log)
// ---------------------------------------------------------------------

@Serializable
sealed class GameEvent {
    abstract val playerIdx: Int

    data class Payday(override val playerIdx: Int, val career: Career, val amount: Rp, val tapera: Rp) : GameEvent()
    data class PaydaySkipped(override val playerIdx: Int) : GameEvent()
    data class LivingCost(override val playerIdx: Int, val amount: Rp) : GameEvent()
    data class UktInterest(override val playerIdx: Int, val amount: Rp) : GameEvent()
    data class KprInterest(override val playerIdx: Int, val assetId: String, val amount: Rp) : GameEvent()
    data class PinjolInterest(override val playerIdx: Int, val amount: Rp) : GameEvent()
    data class SideBusinessPaid(override val playerIdx: Int, val amount: Rp) : GameEvent()
    data class SideBusinessEnded(override val playerIdx: Int) : GameEvent()
    data class FuelSubsidyEnded(override val playerIdx: Int) : GameEvent()
    data class LandlordRentEnded(override val playerIdx: Int) : GameEvent()
    data class CheapRentEnded(override val playerIdx: Int) : GameEvent()
    data class StoleProjectFunds(override val playerIdx: Int, val amount: Rp, val newHeat: Int) : GameEvent()
    data class KpkStingMiss(override val playerIdx: Int) : GameEvent()
    data class KpkStingCaught(override val playerIdx: Int, val cashLost: Rp) : GameEvent()
    data class Married(override val playerIdx: Int, val lavish: Boolean, val cost: Rp, val happiness: Int) : GameEvent()
    data class ChildBorn(override val playerIdx: Int, val childId: String) : GameEvent()
    data class SchoolFunded(override val playerIdx: Int, val childIdx: Int, val private: Boolean, val cost: Rp) : GameEvent()
    data class EnteredPoliticianPath(override val playerIdx: Int, val corrupt: Boolean, val dowry: Rp) : GameEvent()
    data class PoliticianEntryFailed(override val playerIdx: Int, val reason: String) : GameEvent()
    data class NepotismPerk(override val playerIdx: Int, val gain: Rp) : GameEvent()
    data class Retired(override val playerIdx: Int, val choice: RetirementChoice, val score: Rp, val wargaTeladan: Boolean) : GameEvent()
    // Generic event/luck card draw — used by CardResolver for HUD/log
    data class CardDrawn(override val playerIdx: Int, val cardId: String, val isLuck: Boolean) : GameEvent()
    data class CashDelta(override val playerIdx: Int, val amount: Rp, val reason: String) : GameEvent()
    data class HappinessDelta(override val playerIdx: Int, val delta: Int, val reason: String) : GameEvent()
    data class SkipTurn(override val playerIdx: Int, val laps: Int) : GameEvent()
    data class Moved(override val playerIdx: Int, val fromTile: Int, val toTile: Int) : GameEvent()
    data class LapCompleted(override val playerIdx: Int, val laps: Int) : GameEvent()
    data class AssetPurchased(override val playerIdx: Int, val assetId: String, val name: String) : GameEvent()
    data class TokenAwarded(override val playerIdx: Int, val token: String) : GameEvent()
    data class LoanTaken(override val playerIdx: Int, val principal: Rp, val interestPct: Float) : GameEvent()
    data class DebtFlagged(override val playerIdx: Int, val flag: String) : GameEvent()
    object Empty : GameEvent() { override val playerIdx: Int = -1 }
}
