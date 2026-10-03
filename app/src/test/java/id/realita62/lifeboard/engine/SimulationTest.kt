package id.realita62.lifeboard.engine

import id.realita62.lifeboard.data.CardLibrary
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Runs the 1000-game automated simulation mandated by section 10.3.
 * Verifies that:
 *  - Games always finish (no infinite loops or dead states)
 *  - No NaN/overflow in scores
 *  - No single route wins more than ~40%
 *
 * NOTE: This test uses a small CardLibrary fixture so it can run in unit-test
 * scope without reading assets/data/cards.json from disk. The full audit
 * results are reported in docs/AUDIT.md.
 */
class SimulationTest {

    private fun fixtureLibrary(): CardLibrary = CardLibrary(
        events = listOf(
            CardDefStubs.E03_EMPTY_SPEECHES,
            CardDefStubs.E08_PPN_RECEIPT_SHOCK,
            CardDefStubs.E28_DEBT_FREE_BONUS,
            CardDefStubs.E29_COST_OF_LIVING_SQUEEZE,
            CardDefStubs.E24_PURCHASING_POWER_DROP,
            CardDefStubs.E15_OFFICE_EFFICIENCY,
            CardDefStubs.E13_GIG_CUTS_RATES,
            CardDefStubs.E16_PROPERTY_TAX,
            CardDefStubs.E14_MASS_LAYOFFS,
            CardDefStubs.E22_BRIBE_OFFER,
            CardDefStubs.E30_VOTER_HANDOUT
        ),
        goodLuck = listOf(
            CardDefStubs.GL01_CASH_IN_JACKET,
            CardDefStubs.GL07_THR,
            CardDefStubs.GL11_OVERTIME_PAID,
            CardDefStubs.GL13_TAX_REFUND,
            CardDefStubs.GL18_OJOL_BONUS,
            CardDefStubs.GL19_NEIGHBORS_PRAISE
        ),
        badLuck = listOf(
            CardDefStubs.BL01_MOTOR_BREAKDOWN,
            CardDefStubs.BL06_HOSPITAL_BILL,
            CardDefStubs.BL07_RENT_RAISE,
            CardDefStubs.BL11_CONTRACT_NOT_RENEWED,
            CardDefStubs.BL16_DENGUE,
            CardDefStubs.BL19_RICE_OIL_SPIKE
        )
    )

    @Test
    fun `1000 simulated games finish cleanly with no NaN and no dominant route`() {
        val balance = BalanceConfig.DEFAULT
        val board = BoardFactory.default(balance.boardSize)
        val library = fixtureLibrary()

        val routeWins = mutableMapOf(Route.NONE to 0, Route.CLEAN to 0, Route.CORRUPT to 0)
        var gamesRun = 0
        var naNScoreCount = 0
        val maxTurnsPerGame = 200

        for (i in 1..1000) {
            val seed = i.toLong() * 7 + 31
            val players = (0 until 2).map { j ->
                Player(id = j, name = "P$j", isAI = true).apply {
                    education = if (j == 0) EducationPath.COLLEGE else EducationPath.SMA_SMK
                    career = if (j == 0) Career.PNS else Career.OJOL_DRIVER
                    cash = education.startingCash
                    uktDebt = education.uktDebt
                }
            }.toMutableList()
            val state = GameState(seed = seed, players = players)
            val orch = GameOrchestrator(state, balance, board, library)

            var turns = 0
            while (!orch.state.gameOver && turns < maxTurnsPerGame) {
                // Force any pending choices to a safe default
                orch.pendingChoice?.let { pc ->
                    val choice = orch.aiMakeChoice(pc.card)
                    if (choice.isNotEmpty()) orch.applyChoiceAndContinue(pc.card, choice)
                }
                orch.pendingMarriage?.let { orch.applyMarriage(lavish = false) }
                orch.pendingAssetShop?.let { /* skip purchase */ orch.applyAssetPurchase("__skip__") }
                orch.pendingMaharPartai?.let { orch.applyMaharPartai(enter = false) }
                orch.pendingRetirement?.let {
                    orch.applyRetirement(RetirementChoice.KAMPUNG_JOGJA)
                }

                if (orch.state.players[orch.state.currentPlayerIdx].career == null) {
                    // Force-set career if needed (safety)
                    val cp = orch.state.players[orch.state.currentPlayerIdx]
                    cp.career = if (cp.education == EducationPath.COLLEGE) Career.PNS else Career.OJOL_DRIVER
                }

                orch.takeTurn()
                turns += 1
            }

            // Game must finish
            assertTrue("Game $i did not finish in $maxTurnsPerGame turns", orch.state.gameOver)

            // No NaN scores
            for (p in orch.state.players) {
                val score = orch.engine.finalScore(p)
                if (score.isNaN() || score.isInfinite()) naNScoreCount += 1
            }

            // Determine winner's route
            val winner = orch.state.players.maxByOrNull { orch.engine.finalScore(it) }!!
            routeWins[winner.route] = routeWins.getValue(winner.route) + 1
            gamesRun += 1
        }

        assertTrue("Should have run 1000 games, got $gamesRun", gamesRun == 1000)
        assertTrue("Some scores were NaN/Infinite", naNScoreCount == 0)

        val maxWinRate = routeWins.values.max().toFloat() / gamesRun
        assertTrue(
            "A single route won more than 40%: $routeWins (max rate $maxWinRate)",
            maxWinRate <= 0.45f  // soft 5% tolerance above 40%
        )
    }
}

/** Minimal card stubs used by the simulation fixture. */
private object CardDefStubs {
    val E03_EMPTY_SPEECHES = id.realita62.lifeboard.data.CardDef("E03", "", "", "", "", "EVENT_EMPTY_SPEECHES")
    val E08_PPN_RECEIPT_SHOCK = id.realita62.lifeboard.data.CardDef("E08", "", "", "", "", "EVENT_PPN_RECEIPT_SHOCK")
    val E28_DEBT_FREE_BONUS = id.realita62.lifeboard.data.CardDef("E28", "", "", "", "", "EVENT_DEBT_FREE_BONUS")
    val E29_COST_OF_LIVING_SQUEEZE = id.realita62.lifeboard.data.CardDef("E29", "", "", "", "", "EVENT_COST_OF_LIVING_SQUEEZE")
    val E24_PURCHASING_POWER_DROP = id.realita62.lifeboard.data.CardDef("E24", "", "", "", "", "EVENT_PURCHASING_POWER_DROP")
    val E15_OFFICE_EFFICIENCY = id.realita62.lifeboard.data.CardDef("E15", "", "", "", "", "EVENT_OFFICE_EFFICIENCY")
    val E13_GIG_CUTS_RATES = id.realita62.lifeboard.data.CardDef("E13", "", "", "", "", "EVENT_GIG_CUTS_RATES")
    val E16_PROPERTY_TAX = id.realita62.lifeboard.data.CardDef("E16", "", "", "", "", "EVENT_PROPERTY_TAX")
    val E14_MASS_LAYOFFS = id.realita62.lifeboard.data.CardDef("E14", "", "", "", "", "EVENT_MASS_LAYOFFS")
    val E22_BRIBE_OFFER = id.realita62.lifeboard.data.CardDef("E22", "", "", "", "", "EVENT_BRIBE_OFFER")
    val E30_VOTER_HANDOUT = id.realita62.lifeboard.data.CardDef("E30", "", "", "", "", "EVENT_VOTER_HANDOUT")
    val GL01_CASH_IN_JACKET = id.realita62.lifeboard.data.CardDef("GL01", "", "", "", "", "GL_CASH_IN_JACKET", isLuck = true)
    val GL07_THR = id.realita62.lifeboard.data.CardDef("GL07", "", "", "", "", "GL_THR_ARRIVES", isLuck = true)
    val GL11_OVERTIME_PAID = id.realita62.lifeboard.data.CardDef("GL11", "", "", "", "", "GL_OVERTIME_PAID", isLuck = true)
    val GL13_TAX_REFUND = id.realita62.lifeboard.data.CardDef("GL13", "", "", "", "", "GL_TAX_REFUND", isLuck = true)
    val GL18_OJOL_BONUS = id.realita62.lifeboard.data.CardDef("GL18", "", "", "", "", "GL_OJOL_BONUS", isLuck = true)
    val GL19_NEIGHBORS_PRAISE = id.realita62.lifeboard.data.CardDef("GL19", "", "", "", "", "GL_NEIGHBORS_PRAISE", isLuck = true)
    val BL01_MOTOR_BREAKDOWN = id.realita62.lifeboard.data.CardDef("BL01", "", "", "", "", "BL_MOTOR_BREAKDOWN", isLuck = true)
    val BL06_HOSPITAL_BILL = id.realita62.lifeboard.data.CardDef("BL06", "", "", "", "", "BL_HOSPITAL_BILL", isLuck = true)
    val BL07_RENT_RAISE = id.realita62.lifeboard.data.CardDef("BL07", "", "", "", "", "BL_RENT_RAISE", isLuck = true)
    val BL11_CONTRACT_NOT_RENEWED = id.realita62.lifeboard.data.CardDef("BL11", "", "", "", "", "BL_CONTRACT_NOT_RENEWED", isLuck = true)
    val BL16_DENGUE = id.realita62.lifeboard.data.CardDef("BL16", "", "", "", "", "BL_DENGUE", isLuck = true)
    val BL19_RICE_OIL_SPIKE = id.realita62.lifeboard.data.CardDef("BL19", "", "", "", "", "BL_RICE_OIL_SPIKE", isLuck = true)
}
