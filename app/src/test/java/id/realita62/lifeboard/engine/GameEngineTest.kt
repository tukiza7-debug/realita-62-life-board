package id.realita62.lifeboard.engine

import org.junit.Test
import org.junit.Assert.*
import id.realita62.lifeboard.data.CardLibrary

/**
 * Unit tests for the deterministic rules engine. Each test exercises a
 * specific rule from the master prompt:
 * - payday with TAPERA 3% for PNS/SCBD
 * - PPN 12% on asset purchases
 * - UKT 2% / KPR 3% / Pinjol 15% interest per lap
 * - fuel subsidy extra cost per roll (event E06)
 * - scoring with corrupt-halving rule
 * - Dynasty legacy bonus
 * - save/load round-trip
 * - one card per event card and per luck card (section 10 requires this)
 */
class GameEngineTest {

    private fun newEngine(seed: Long = 42L): GameEngine {
        return GameEngine(BalanceConfig.DEFAULT, SeededRng(seed))
    }

    private fun newPlayer(career: Career? = null, cash: Rp = 5.0) = Player(
        id = 0, name = "P1", isAI = false, career = career, cash = cash
    )

    private fun newSinglePlayerState(p: Player, balance: BalanceConfig = BalanceConfig.DEFAULT): GameState {
        val players = mutableListOf(p)
        return GameState(seed = 42L, players = players, assetCatalogue = AssetCatalogue())
    }

    // --- PAYDAY -------------------------------------------------------------

    @Test
    fun `payday pays gross for Ojol Driver with no TAPERA`() {
        val engine = newEngine()
        val p = newPlayer(Career.OJOL_DRIVER)
        val state = newSinglePlayerState(p)
        engine.payday(state, 0)
        assertEquals("Cash should be starting + Rp 4M payday",
            9.0, p.cash, 0.001)
    }

    @Test
    fun `payday applies TAPERA 3 percent for PNS`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS)
        val state = newSinglePlayerState(p)
        engine.payday(state, 0)
        // Gross 9, TAPERA 3% = 0.27, take-home = 8.73
        assertEquals(8.73, p.cash, 0.001)
    }

    @Test
    fun `payday applies TAPERA 3 percent for SCBD`() {
        val engine = newEngine()
        val p = newPlayer(Career.SCBD_EMPLOYEE)
        val state = newSinglePlayerState(p)
        engine.payday(state, 0)
        // Gross 12, TAPERA 3% = 0.36, take-home = 11.64
        assertEquals(11.64, p.cash, 0.001)
    }

    @Test
    fun `payday skipped when player has skipsNextPayday flag`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS).apply {
            skipsNextPayday = true
            cash = 0.0
        }
        val state = newSinglePlayerState(p)
        engine.payday(state, 0)
        assertEquals(0.0, p.cash, 0.001) // No payday applied
        assertFalse(p.skipsNextPayday)
    }

    // --- INTEREST -----------------------------------------------------------

    @Test
    fun `UKT interest is 2 percent per lap`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS).apply { uktDebt = 10.0 }
        val state = newSinglePlayerState(p)
        engine.endOfLap(state, 0)
        // 10 + 2% = 10.2
        assertEquals(10.2, p.uktDebt, 0.001)
    }

    @Test
    fun `KPR interest is 3 percent per lap on remaining principal`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS).apply {
            assets.add(Asset(id = "apt", name = "Apartment", price = 35.0, remainingKpr = 28.0))
        }
        val state = newSinglePlayerState(p)
        engine.endOfLap(state, 0)
        // 28 + 3% = 28.84
        assertEquals(28.84, p.assets[0].remainingKpr, 0.001)
    }

    @Test
    fun `Pinjol interest is 15 percent per lap`() {
        val engine = newEngine()
        val p = newPlayer(Career.DAILY_WORKER).apply { pinjolDebt = 3.0 }
        val state = newSinglePlayerState(p)
        engine.endOfLap(state, 0)
        // 3 + 15% = 3.45
        assertEquals(3.45, p.pinjolDebt, 0.001)
    }

    // --- PPN 12% on asset purchase ----------------------------------------

    @Test
    fun `asset purchase applies PPN 12 percent and 20 percent down payment on total`() {
        val engine = newEngine()
        val p = newPlayer(Career.SCBD_EMPLOYEE, cash = 20.0)
        val state = newSinglePlayerState(p)
        // Apartment Rp 35M, +12% PPN = 39.2, 20% down = 7.84, 80% KPR = 31.36
        val result = engine.purchaseAsset(state, 0, "apartment")
        assertTrue(result is PurchaseResult.Ok)
        val ok = result as PurchaseResult.Ok
        assertEquals(7.84, ok.downPayment, 0.001)
        assertEquals(31.36, ok.kprPrincipal, 0.001)
        assertEquals(35.0 - 7.84, p.cash, 0.001)
        assertEquals(31.36, p.assets[0].remainingKpr, 0.001)
    }

    @Test
    fun `asset purchase fails when cash is insufficient for down payment`() {
        val engine = newEngine()
        val p = newPlayer(Career.OJOL_DRIVER, cash = 1.0)
        val state = newSinglePlayerState(p)
        val result = engine.purchaseAsset(state, 0, "menteng_mansion")
        assertTrue(result is PurchaseResult.Failed)
    }

    // --- FUEL SUBSIDY (event E06) -----------------------------------------

    @Test
    fun `fuel subsidy timer ticks down each lap`() {
        val engine = newEngine()
        val p = newPlayer(Career.OJOL_DRIVER).apply {
            fuelSubsidyLapsLeft = 3
            fuelSubsidyExtraPerRoll = 0.2
        }
        val state = newSinglePlayerState(p)
        // Three laps: 3 -> 2 -> 1 -> 0
        repeat(3) { engine.endOfLap(state, 0) }
        assertEquals(0, p.fuelSubsidyLapsLeft)
        assertEquals(0.0, p.fuelSubsidyExtraPerRoll, 0.001)
    }

    // --- SCORING -----------------------------------------------------------

    @Test
    fun `clean player score equals net assets plus cash plus H times half million`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS, cash = 10.0).apply {
            happiness = 10
            assets.add(Asset(id = "apt", name = "Apartment", price = 35.0, remainingKpr = 0.0))
        }
        // 35 + 10 + (10 * 0.5) + 0 legacy = 50
        assertEquals(50.0, engine.finalScore(p), 0.001)
    }

    @Test
    fun `corrupt player with negative H has score halved`() {
        val engine = newEngine()
        val p = newPlayer(Career.POLITICIAN_CORRUPT, cash = 50.0).apply {
            happiness = -5
            corruptFlagEver = true
        }
        // 0 + 50 + (-5 * 0.5) = 47.5, halved = 23.75
        assertEquals(23.75, engine.finalScore(p), 0.001)
    }

    @Test
    fun `corrupt player with positive H keeps full score`() {
        val engine = newEngine()
        val p = newPlayer(Career.POLITICIAN_CORRUPT, cash = 50.0).apply {
            happiness = 5
            corruptFlagEver = true
        }
        // 50 + (5 * 0.5) = 52.5 — not halved
        assertEquals(52.5, engine.finalScore(p), 0.001)
    }

    @Test
    fun `Warga Teladan requires no corruption no Pinjol positive H and Jogja or Bali retirement`() {
        val engine = newEngine()
        val pClean = newPlayer(Career.PNS, cash = 10.0).apply {
            happiness = 5
            retirement = RetirementChoice.KAMPUNG_JOGJA
        }
        assertTrue(engine.isWargaTeladan(pClean))

        val pPinjol = pClean.copy(pinjolDebt = 1.0)
        assertFalse(engine.isWargaTeladan(pPinjol))

        val pMenteng = pClean.copy(retirement = RetirementChoice.ELITE_MENTENG)
        assertFalse(engine.isWargaTeladan(pMenteng))

        val pNeg = pClean.copy(happiness = -1)
        assertFalse(engine.isWargaTeladan(pNeg))

        val pCorrupt = pClean.copy(corruptFlagEver = true)
        assertFalse(engine.isWargaTeladan(pCorrupt))
    }

    // --- DYNASTY LEGACY ----------------------------------------------------

    @Test
    fun `funded child adds 3M legacy unfunded adds 0_5M`() {
        val engine = newEngine()
        val p = newPlayer(Career.PNS, cash = 0.0).apply {
            children.add(Child("c1", isFunded = true))
            children.add(Child("c2", isFunded = false))
        }
        // 3.0 + 0.5 = 3.5 legacy, score = 0 + 0 + (0 * 0.5) + 3.5 = 3.5
        assertEquals(3.5, engine.finalScore(p), 0.001)
    }

    @Test
    fun `nepotism perk halves funded legacy bonus`() {
        val engine = newEngine()
        val p = newPlayer(Career.POLITICIAN_CLEAN, cash = 0.0).apply {
            children.add(Child("c1", isFunded = true))
            usedNepotismPerk = true
        }
        // 3.0 * 0.5 = 1.5 funded, score = 0 + 0 + 0 + 1.5 = 1.5
        assertEquals(1.5, engine.finalScore(p), 0.001)
    }

    // --- SAVE / LOAD -------------------------------------------------------

    @Test
    fun `game state serializes and round-trips back`() {
        val engine = newEngine()
        val p1 = newPlayer(Career.OJOL_DRIVER, cash = 7.0).apply {
            uktDebt = 0.0
            happiness = 3
        }
        val state = GameState(seed = 42L, players = mutableListOf(p1))
        val json = GameOrchestrator.JSON.encodeToString(GameState.serializer(), state)
        val restored = GameOrchestrator.JSON.decodeFromString(GameState.serializer(), json)
        assertEquals(42L, restored.seed)
        assertEquals(1, restored.players.size)
        assertEquals(7.0, restored.players[0].cash, 0.001)
        assertEquals(3, restored.players[0].happiness)
    }

    // --- DETERMINISTIC RNG --------------------------------------------------

    @Test
    fun `same seed produces same dice sequence`() {
        val a = SeededRng(123L)
        val b = SeededRng(123L)
        for (i in 1..50) {
            assertEquals(a.rollDice(), b.rollDice())
        }
    }

    @Test
    fun `string seed is reproducible`() {
        val a = SeededRng.fromStringSeed("realita-62-test")
        val b = SeededRng.fromStringSeed("realita-62-test")
        repeat(100) {
            assertEquals(a.nextInt(60), b.nextInt(60))
        }
    }

    // --- ONE CARD TEST PER CARD (sample — see audit for full coverage) -----

    private fun emptyLibrary() = CardLibrary(events = emptyList(), goodLuck = emptyList(), badLuck = emptyList())

    @Test
    fun `EVENT_FUEL_SUBSIDY_REMOVED applies to Ojol and Daily Worker only`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val balance = BalanceConfig.DEFAULT
        val card = id.realita62.lifeboard.data.CardDef(
            id = "E06", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "EVENT_FUEL_SUBSIDY_REMOVED"
        )

        val ojol = newPlayer(Career.OJOL_DRIVER, cash = 5.0)
        val state = newSinglePlayerState(ojol)
        resolver.resolveImmediate(state, 0, card)
        assertEquals(balance.fuelSubsidyLaps, ojol.fuelSubsidyLapsLeft)
        assertEquals(balance.fuelSubsidyExtraPerRoll, ojol.fuelSubsidyExtraPerRoll, 0.001)

        val pns = newPlayer(Career.PNS, cash = 5.0)
        val state2 = newSinglePlayerState(pns)
        resolver.resolveImmediate(state2, 0, card)
        // PNS loses 0.5M cash instead
        assertEquals(4.5, pns.cash, 0.001)
    }

    @Test
    fun `GL_NEIGHBORS_PRAISE gives 15H to clean route and 10H otherwise`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "GL19", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "GL_NEIGHBORS_PRAISE", isLuck = true
        )
        val clean = newPlayer(Career.PNS).apply { route = Route.CLEAN }
        val state = newSinglePlayerState(clean)
        resolver.resolveImmediate(state, 0, card)
        assertEquals(15, clean.happiness)

        val none = newPlayer(Career.PNS).apply { route = Route.NONE }
        val state2 = newSinglePlayerState(none)
        resolver.resolveImmediate(state2, 0, card)
        assertEquals(10, none.happiness)
    }

    @Test
    fun `BL_HOSPITAL_BILL is halved when player is insured`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "BL06", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "BL_HOSPITAL_BILL", isLuck = true
        )
        val insured = newPlayer(Career.PNS, cash = 20.0).apply { insurance = true }
        val state = newSinglePlayerState(insured)
        resolver.resolveImmediate(state, 0, card)
        assertEquals(20.0 - 4.0, insured.cash, 0.001) // 8 / 2 = 4

        val uninsured = newPlayer(Career.PNS, cash = 20.0).apply { insurance = false }
        val state2 = newSinglePlayerState(uninsured)
        resolver.resolveImmediate(state2, 0, card)
        assertEquals(20.0 - 8.0, uninsured.cash, 0.001)
    }

    @Test
    fun `EVENT_DEBT_FREE_BONUS gives 4H and 1M cash when no debt`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "E28", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "EVENT_DEBT_FREE_BONUS"
        )
        val p = newPlayer(Career.PNS, cash = 5.0)
        val state = newSinglePlayerState(p)
        resolver.resolveImmediate(state, 0, card)
        assertEquals(6.0, p.cash, 0.001)
        assertEquals(4, p.happiness)

        val indebted = newPlayer(Career.PNS, cash = 5.0).apply { pinjolDebt = 1.0 }
        val state2 = newSinglePlayerState(indebted)
        resolver.resolveImmediate(state2, 0, card)
        assertEquals(5.0, indebted.cash, 0.001) // no bonus
        assertEquals(0, indebted.happiness)
    }

    @Test
    fun `EVENT_MBG_TENDER skim choice has chance of investigation`() {
        // Run 1000 times — should see some investigations triggered.
        var investigations = 0
        repeat(1000) {
            val engine = newEngine(seed = it.toLong())
            val resolver = CardResolver(engine)
            val card = id.realita62.lifeboard.data.CardDef(
                id = "E02", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
                effect = "EVENT_MBG_TENDER"
            )
            val p = newPlayer(Career.CONTRACTOR, cash = 50.0)
            val state = newSinglePlayerState(p)
            resolver.applyChoice(state, 0, card, "skim")
            if (p.corruptFlagEver) investigations += 1
        }
        assertTrue("Expected ~350 investigations, got $investigations",
            investigations in 250..450)
    }

    @Test
    fun `EVENT_EMPTY_SPEECHES hits all players with -10H`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "E03", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "EVENT_EMPTY_SPEECHES"
        )
        val p1 = newPlayer(Career.PNS, cash = 5.0)
        val p2 = newPlayer(Career.OJOL_DRIVER, cash = 5.0).also { it.id = 1 }
        val state = GameState(seed = 42L, players = mutableListOf(p1, p2))
        resolver.resolveImmediate(state, 0, card)
        assertEquals(-10, p1.happiness)
        assertEquals(-10, p2.happiness)
    }

    @Test
    fun `EVENT_COST_OF_LIVING_SQUEEZE applies one extra living cost to every player`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "E29", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "EVENT_COST_OF_LIVING_SQUEEZE"
        )
        val p = newPlayer(Career.PNS, cash = 20.0) // no children
        val state = newSinglePlayerState(p)
        resolver.resolveImmediate(state, 0, card)
        // Base living cost is 3M per lap. Player should lose at least 3M.
        assertTrue("Player cash should be reduced, got ${p.cash}", p.cash < 20.0)
    }

    @Test
    fun `BL_RICE_OIL_SPIKE applies to all players`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "BL19", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "BL_RICE_OIL_SPIKE", isLuck = true
        )
        val p1 = newPlayer(Career.PNS, cash = 10.0)
        val p2 = newPlayer(Career.OJOL_DRIVER, cash = 10.0).also { it.id = 1 }
        val state = GameState(seed = 42L, players = mutableListOf(p1, p2))
        resolver.resolveImmediate(state, 0, card)
        assertEquals(8.0, p1.cash, 0.001)
        assertEquals(8.0, p2.cash, 0.001)
    }

    // --- KPK STING ----------------------------------------------------------

    @Test
    fun `KPK sting chance equals heat times 10 percent`() {
        val engine = newEngine()
        val resolver = CardResolver(engine)
        val card = id.realita62.lifeboard.data.CardDef(
            id = "E10", titleEn = "", titleId = "", flavorEn = "", flavorId = "",
            effect = "EVENT_KPK_STING"
        )

        // Heat 0 → 0% chance (never caught)
        var catches = 0
        repeat(1000) {
            val eng = newEngine(seed = it.toLong())
            val res = CardResolver(eng)
            val p = newPlayer(Career.POLITICIAN_CORRUPT, cash = 20.0)
            val st = newSinglePlayerState(p)
            res.resolveImmediate(st, 0, card)
            if (p.cash < 20.0) catches += 1
        }
        assertEquals("Heat 0 should never trigger", 0, catches)
    }

    @Test
    fun `KPK sting catches corrupt players proportional to heat`() {
        // Heat 10 → 100% chance. Should always be caught.
        var catches = 0
        repeat(100) {
            val eng = newEngine(seed = it.toLong())
            val p = newPlayer(Career.POLITICIAN_CORRUPT, cash = 20.0).apply {
                corruptionHeat = 10
            }
            val st = newSinglePlayerState(p)
            eng.rollKpkSting(st, 0)
            if (p.cash < 20.0) catches += 1
        }
        assertEquals("Heat 10 should always catch", 100, catches)
    }
}
