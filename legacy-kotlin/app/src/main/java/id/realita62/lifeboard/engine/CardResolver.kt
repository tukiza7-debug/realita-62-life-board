package id.realita62.lifeboard.engine

import id.realita62.lifeboard.data.CardDef

/**
 * Resolves a card's `effect` string into concrete mutations on GameState.
 *
 * Each case is small, named, and tested. Effects never read Math.random();
 * any randomness goes through the engine's [SeededRng] so the game stays
 * deterministic given a seed.
 *
 * Some cards present the player with a choice (e.g. E02 Skim / Decline).
 * For those, the resolver exposes the *prompt*; the UI calls back with
 * `CardResolver.applyChoice(...)` once the player picks. The choiceless
 * cards resolve immediately.
 */
class CardResolver(val engine: GameEngine) {

    /** True if the card needs a player decision (UI must show a choice dialog). */
    fun needsChoice(card: CardDef): Boolean = card.effect in CHOICE_CARDS

    /** Resolve a card that requires NO player choice. Returns events raised. */
    fun resolveImmediate(state: GameState, playerIdx: Int, card: CardDef): List<GameEvent> {
        val p = state.players[playerIdx]
        val ev = mutableListOf<GameEvent>()
        val balance = engine.balance

        // Savings buffer reduces bad-luck cash loss by 25%.
        fun badLuckAdjusted(amount: Rp): Rp {
            return if (p.cash >= balance.savingsBufferThreshold && card.id.startsWith("BL")) {
                amount * (1.0 - balance.badLuckCashReductionPct.toDouble())
            } else amount
        }
        fun cash(delta: Rp, reason: String) {
            p.cash += delta
            ev += GameEvent.CashDelta(playerIdx, delta, reason)
        }
        fun h(delta: Int, reason: String) {
            p.happiness += delta
            ev += GameEvent.HappinessDelta(playerIdx, delta, reason)
        }
        fun skip(laps: Int) {
            p.tokens.skipTurnLoss += laps
            ev += GameEvent.SkipTurn(playerIdx, laps)
        }
        fun insuranceHalved(amount: Rp): Rp = if (p.insurance) amount * 0.5 else amount

        when (card.effect) {
            // ---- EVENTS ----------------------------------------------------------
            "EVENT_MBG_SKIMMED" -> {
                if (p.children.isNotEmpty()) { cash(-1.5, "MBG clinic"); h(-5, "MBG clinic"); }
            }
            "EVENT_EMPTY_SPEECHES" -> {
                for (i in state.players.indices) {
                    val q = state.players[i]
                    q.happiness -= 10
                    ev += GameEvent.HappinessDelta(i, -10, "Empty speeches")
                }
            }
            "EVENT_TRAPPED_IN_PINJOL" -> {
                // Forced Rp 3M loan at 15% per lap. Voluntary if cash >= 0.
                if (p.cash < 0 || p.cash < balance.baseLivingCostPerLap) {
                    val principal = 3.0
                    p.pinjolDebt += principal
                    p.cash += principal
                    ev += GameEvent.LoanTaken(playerIdx, principal, balance.pinjolInterestPerLapPct)
                }
            }
            "EVENT_KONDANGAN_MUDIK" -> { cash(-1.5, "Kondangan"); skip(1) }
            "EVENT_FUEL_SUBSIDY_REMOVED" -> {
                if (p.career == Career.OJOL_DRIVER || p.career == Career.DAILY_WORKER) {
                    p.fuelSubsidyExtraPerRoll = balance.fuelSubsidyExtraPerRoll
                    p.fuelSubsidyLapsLeft = balance.fuelSubsidyLaps
                    ev += GameEvent.DebtFlagged(playerIdx, "fuel_subsidy_on")
                } else {
                    cash(-0.5, "Fuel price shock")
                }
            }
            "EVENT_TAPERA_LOCKED" -> {
                if (p.career == Career.PNS || p.career == Career.SCBD_EMPLOYEE) h(-3, "TAPERA")
            }
            "EVENT_PPN_RECEIPT_SHOCK" -> {
                for (i in state.players.indices) {
                    val q = state.players[i]
                    q.cash -= 1.0
                    q.happiness -= 3
                    ev += GameEvent.CashDelta(i, -1.0, "PPN shock")
                    ev += GameEvent.HappinessDelta(i, -3, "PPN shock")
                }
            }
            "EVENT_KPK_STING" -> {
                if (p.career == Career.POLITICIAN_CORRUPT) {
                    ev += engine.rollKpkSting(state, playerIdx)
                } else {
                    h(5, "Clean conscience")
                }
            }
            "EVENT_GIG_CUTS_RATES" -> {
                if (p.career == Career.OJOL_DRIVER) cash(-2.0, "Aplikator cuts")
            }
            "EVENT_MASS_LAYOFFS" -> {
                if (p.career == Career.SCBD_EMPLOYEE) {
                    p.skipsNextPayday = true
                    ev += GameEvent.DebtFlagged(playerIdx, "phk")
                }
            }
            "EVENT_OFFICE_EFFICIENCY" -> {
                if (p.career == Career.PNS) { cash(-1.5, "Office efficiency"); h(-3, "Office efficiency") }
            }
            "EVENT_PROPERTY_TAX" -> {
                for (a in p.assets) {
                    val tax = a.price * 0.01
                    p.cash -= tax
                    ev += GameEvent.CashDelta(playerIdx, -tax, "PBB on ${a.id}")
                }
            }
            "EVENT_MORTGAGE_RATE_RESET" -> {
                for (a in p.assets) {
                    if (a.hasKpr) a.kprInterestBoostLapsLeft = 2
                }
                ev += GameEvent.DebtFlagged(playerIdx, "kpr_rate_reset")
            }
            "EVENT_BPJS_QUEUE" -> {
                if (!p.insurance) { skip(1); h(-2, "BPJS queue") }
            }
            "EVENT_COMMUNITY_CLEANUP" -> h(5, "Kerja bakti")
            "EVENT_PURCHASING_POWER_DROP" -> {
                // All incomes -10% this lap. We model this as one-off cash loss = 10% of gross payday.
                val c = p.career ?: return ev
                val loss = c.grossPayday * 0.10
                cash(-loss, "Purchasing power drop")
            }
            "EVENT_CHILD_TOPS_CLASS" -> {
                if (p.children.isNotEmpty()) h(8, "Child tops class")
            }
            "EVENT_HOME_REPAIR_AID" -> {
                val ownsKampung = p.assets.any { it.id == "kampung_house" }
                if (ownsKampung) cash(2.0, "Bedah rumah")
            }
            "EVENT_ROASTED_BY_NETIZENS" -> {
                if (p.career?.isPolitician == true) h(-8, "Roasted by netizens")
                else h(-2, "Roasted by netizens")
            }
            "EVENT_DEBT_FREE_BONUS" -> {
                if (p.hasNoDebt) { cash(1.0, "Debt-free bonus"); h(4, "Debt-free bonus") }
            }
            "EVENT_COST_OF_LIVING_SQUEEZE" -> {
                for (i in state.players.indices) {
                    val q = state.players[i]
                    val extra = q.livingCostThisLap(balance.baseLivingCostPerLap, balance.perChildLivingCost)
                    q.cash -= extra
                    ev += GameEvent.CashDelta(i, -extra, "Cost-of-living squeeze")
                    if (q.cash < balance.savingsBufferThreshold) {
                        q.happiness -= 2
                        ev += GameEvent.HappinessDelta(i, -2, "No savings buffer")
                    }
                }
            }

            // ---- CHOICE-REQUIRED EVENTS (these are immediate when chosen) -----
            // (handled by applyChoice below; nothing to do here)

            // ---- GOOD LUCK -------------------------------------------------------
            "GL_CASH_IN_JACKET" -> cash(1.0, "Old jacket")
            "GL_SIDE_HUSTLE_VIRAL" -> { cash(3.0, "Viral side hustle"); h(5, "Viral side hustle") }
            "GL_NEIGHBOR_REPAYS" -> cash(2.0, "Neighbor repays")
            "GL_FREE_CHECKUP" -> {
                h(5, "Puskesmas")
                p.tokens.clinicCostCancel += 1
                ev += GameEvent.TokenAwarded(playerIdx, "cancel_clinic")
            }
            "GL_LUCKY_ARISAN" -> cash(5.0, "Arisan win")
            "GL_GOTONG_ROYONG" -> {
                p.tokens.cancelNegativeEvent += 1
                ev += GameEvent.TokenAwarded(playerIdx, "cancel_event")
            }
            "GL_THR_ARRIVES" -> cash(4.0, "THR")
            "GL_TOLL_PAID" -> {
                p.tokens.skipTurnLoss += 1
                ev += GameEvent.TokenAwarded(playerIdx, "skip_turn_loss")
            }
            "GL_PAYDAY_PROMO" -> { cash(1.0, "Promo warung"); h(3, "Promo warung") }
            "GL_SCHOLARSHIP" -> {
                if (p.children.isNotEmpty()) {
                    p.tokens.waiveNextSchoolFee += 1
                    ev += GameEvent.TokenAwarded(playerIdx, "waive_school_fee")
                } else cash(2.0, "Scholarship cash")
            }
            "GL_OVERTIME_PAID" -> {
                val c = p.career
                val amount = if (c == Career.OJOL_DRIVER || c == Career.DAILY_WORKER) 2.0 else 3.0
                cash(amount, "Overtime paid")
            }
            "GL_UNCLE_TREATS" -> h(8, "Om traktir")
            "GL_TAX_REFUND" -> cash(3.0, "Tax refund")
            "GL_CHEAP_RENTAL" -> {
                p.cheapRentDiscountLapsLeft = 2
                p.cheapRentDiscountPct = 0.50f
                ev += GameEvent.DebtFlagged(playerIdx, "cheap_rent")
            }
            "GL_LOAN_WAIVER" -> {
                if (p.hasPinjol) {
                    // Waive 1 lap of Pinjol interest — subtract one period of interest from principal.
                    val interest = p.pinjolDebt * balance.pinjolInterestPerLapPct.toDouble()
                    p.pinjolDebt = (p.pinjolDebt - interest).coerceAtLeast(0.0)
                    ev += GameEvent.CashDelta(playerIdx, interest, "Pinjol interest waived")
                } else h(3, "No loan to waive")
            }
            "GL_VILLAGE_RAFFLE" -> cash(2.0, "Raffle prize")
            "GL_FRIEND_REFERRAL" -> {
                // Roll again — UI handles by allowing another dice roll this turn.
                ev += GameEvent.TokenAwarded(playerIdx, "roll_again")
            }
            "GL_OJOL_BONUS" -> {
                val amount = if (p.career == Career.OJOL_DRIVER) 2.0 else 1.0
                cash(amount, "Ojol bonus")
            }
            "GL_NEIGHBORS_PRAISE" -> {
                val bonus = if (p.route == Route.CLEAN) 15 else 10
                h(bonus, "Warga memuji")
            }
            "GL_HARVEST_FROM_HOME" -> { cash(1.0, "Kiriman kampung"); h(4, "Kiriman kampung") }

            // ---- BAD LUCK --------------------------------------------------------
            "BL_MOTOR_BREAKDOWN" -> cash(-badLuckAdjusted(2.0), "Motor mogok")
            "BL_PHONE_SNATCHED" -> { cash(-badLuckAdjusted(3.0), "HP dijambret"); h(-5, "HP dijambret") }
            "BL_FLOOD" -> { cash(-badLuckAdjusted(2.0), "Banjir"); skip(1) }
            "BL_OVERTIME_UNPAID" -> cash(-badLuckAdjusted(2.0), "Lembur tak dibayar")
            "BL_FAKE_SHOP" -> cash(-badLuckAdjusted(3.0), "Toko online palsu")
            "BL_HOSPITAL_BILL" -> cash(-insuranceHalved(badLuckAdjusted(8.0)), "Tagihan RS")
            "BL_RENT_RAISE" -> {
                p.landlordRentExtraLapsLeft = 2
                p.landlordRentExtraPerLap = 1.0
                ev += GameEvent.DebtFlagged(playerIdx, "rent_raise")
            }
            "BL_VIRAL_AIB" -> h(-8, "Aib viral")
            "BL_FUEL_QUEUE" -> {
                skip(1)
                if (p.career == Career.OJOL_DRIVER) cash(-2.0, "Antre BBM")
            }
            "BL_LPG_SHORTAGE" -> { cash(-1.0, "Gas melon langka"); h(-3, "Gas melon langka") }
            "BL_CONTRACT_NOT_RENEWED" -> {
                if (p.career != Career.PNS && p.career?.isPolitician != true) {
                    p.skipsNextPayday = true
                    ev += GameEvent.DebtFlagged(playerIdx, "contract_not_renewed")
                }
            }
            "BL_WEDDING_INVITES" -> { cash(-2.0, "Undangan nikahan"); h(-3, "Undangan nikahan") }
            "BL_SCHOOL_FEE_HIKE" -> {
                val amount = if (p.children.isNotEmpty()) 4.0 else 1.0
                cash(-badLuckAdjusted(amount), "Uang gedung")
            }
            "BL_BLACKOUT_FRIDGE" -> cash(-1.0, "Listrik padam")
            "BL_TRAFFIC_TICKET" -> cash(-1.0, "Ditilang")
            "BL_DENGUE" -> {
                val amount = insuranceHalved(badLuckAdjusted(3.0))
                cash(-amount, "Demam berdarah"); h(-5, "Demam berdarah")
            }
            "BL_DEBT_COLLECTOR" -> {
                if (p.hasPinjol) h(-8, "Debt collector") else h(-2, "Debt collector")
            }
            "BL_ROOF_LEAK" -> cash(-badLuckAdjusted(2.0), "Atap bocor")
            "BL_RICE_OIL_SPIKE" -> {
                for (i in state.players.indices) {
                    state.players[i].cash -= 2.0
                    ev += GameEvent.CashDelta(i, -2.0, "Harga beras/minyak naik")
                }
            }
            "BL_FRIEND_DISAPPEARS" -> { cash(-2.0, "Teman menghilang"); h(-4, "Teman menghilang") }

            else -> {
                // Choice cards (E02, E09, E11, E12, E18, E20, E21, E22, E26, E30) are no-ops here.
                // The UI calls CardResolver.applyChoice to resolve them after the player picks.
            }
        }

        // Good luck cap per card (max 5M per card) — applied AFTER the effect.
        if (card.isLuck && card.id.startsWith("GL")) {
            // No-op: we have already capped the cash gains by design of each card.
            // The per-lap cap on draws is enforced in CardDeck.drawGoodLuck.
        }

        return ev
    }

    /** Apply a player's choice for a choice card. Returns events raised. */
    fun applyChoice(state: GameState, playerIdx: Int, card: CardDef, choice: String): List<GameEvent> {
        val p = state.players[playerIdx]
        val ev = mutableListOf<GameEvent>()
        val balance = engine.balance
        fun cash(delta: Rp, reason: String) { p.cash += delta; ev += GameEvent.CashDelta(playerIdx, delta, reason) }
        fun h(delta: Int, reason: String) { p.happiness += delta; ev += GameEvent.HappinessDelta(playerIdx, delta, reason) }

        when (card.effect) {
            "EVENT_MBG_TENDER" -> when (choice) {
                "skim" -> {
                    cash(8.0, "MBG tender skim")
                    if (engine.rng.chance(0.35f)) {
                        cash(-12.0, "Investigation fine")
                        h(-15, "Investigation")
                        p.corruptFlagEver = true
                        p.route = Route.CORRUPT
                        ev += GameEvent.DebtFlagged(playerIdx, "corrupt_flag")
                    }
                }
                "decline" -> h(5, "Declined skim")
            }
            "EVENT_PARTY_DOWRY_OFFER" -> when (choice) {
                "clean", "corrupt" -> ev += engine.enterPoliticianPath(state, playerIdx, corrupt = (choice == "corrupt"))
                "decline" -> h(2, "Declined politics")
            }
            "EVENT_PORK_BARREL" -> when (choice) {
                "corrupt" -> {
                    cash(10.0, "Pork barrel")
                    p.corruptionHeat += 2
                    p.corruptFlagEver = true
                    ev += GameEvent.DebtFlagged(playerIdx, "heat_up")
                }
                "clean" -> h(4, "Clean pork barrel")
            }
            "EVENT_PRIVATE_SCHOOL_FEE" -> when (choice) {
                "private" -> {
                    cash(-5.0, "Private school fee")
                    if (p.children.isNotEmpty()) {
                        val idx = p.children.lastIndex
                        p.children[idx] = p.children[idx].copy(isFunded = true, isPrivateSchool = true)
                    }
                }
                "public" -> h(-3, "Public school")
            }
            "EVENT_RELATIVE_NEEDS_HELP" -> when (choice) {
                "help" -> { cash(-2.0, "Help saudara"); h(4, "Help saudara") }
                "refuse" -> h(-4, "Refuse saudara")
            }
            "EVENT_GAMBLING_AD" -> when (choice) {
                "join" -> { cash(-3.0, "Judi online"); h(-5, "Judi online") }
                "ignore" -> h(2, "Tolak judi")
            }
            "EVENT_SIDE_BUSINESS" -> when (choice) {
                "start" -> {
                    cash(-3.0, "Side business start")
                    if (engine.rng.chance(balance.sideBusinessFlopChance)) {
                        ev += GameEvent.DebtFlagged(playerIdx, "side_business_flop")
                    } else {
                        p.sideBusinessLapsLeft = balance.sideBusinessLaps
                        p.sideBusinessIncomePerLap = balance.sideBusinessIncomePerLap
                        ev += GameEvent.DebtFlagged(playerIdx, "side_business_on")
                    }
                }
                "decline" -> { /* no-op */ }
            }
            "EVENT_BRIBE_OFFER" -> when (choice) {
                "accept" -> {
                    cash(4.0, "Bribe accepted")
                    h(-5, "Bribe accepted")
                    p.corruptFlagEver = true
                    p.corruptionHeat += 1
                    ev += GameEvent.DebtFlagged(playerIdx, "corrupt_flag")
                }
                "decline" -> h(3, "Declined bribe")
            }
            "EVENT_VOTER_HANDOUT" -> when (choice) {
                "accept" -> {
                    cash(0.5, "Voter handout")
                    h(-3, "Voter handout")
                    if (p.career == Career.POLITICIAN_CORRUPT) {
                        p.corruptionHeat += 1
                        ev += GameEvent.DebtFlagged(playerIdx, "heat_up")
                    }
                }
                "refuse" -> h(3, "Refused handout")
            }
        }

        return ev
    }

    companion object {
        /** Effect IDs that always require a player decision before resolving. */
        val CHOICE_CARDS = setOf(
            "EVENT_MBG_TENDER",
            "EVENT_PARTY_DOWRY_OFFER",
            "EVENT_PORK_BARREL",
            "EVENT_PRIVATE_SCHOOL_FEE",
            "EVENT_RELATIVE_NEEDS_HELP",
            "EVENT_GAMBLING_AD",
            "EVENT_SIDE_BUSINESS",
            "EVENT_BRIBE_OFFER",
            "EVENT_VOTER_HANDOUT"
        )

        /** Choices for each choice card — used by UI to render buttons. */
        fun choicesFor(effect: String): List<String> = when (effect) {
            "EVENT_MBG_TENDER" -> listOf("skim", "decline")
            "EVENT_PARTY_DOWRY_OFFER" -> listOf("clean", "corrupt", "decline")
            "EVENT_PORK_BARREL" -> listOf("corrupt", "clean")
            "EVENT_PRIVATE_SCHOOL_FEE" -> listOf("private", "public")
            "EVENT_RELATIVE_NEEDS_HELP" -> listOf("help", "refuse")
            "EVENT_GAMBLING_AD" -> listOf("join", "ignore")
            "EVENT_SIDE_BUSINESS" -> listOf("start", "decline")
            "EVENT_BRIBE_OFFER" -> listOf("accept", "decline")
            "EVENT_VOTER_HANDOUT" -> listOf("accept", "refuse")
            else -> emptyList()
        }
    }
}
