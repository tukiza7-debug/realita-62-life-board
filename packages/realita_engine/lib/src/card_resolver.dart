/// Resolves a card's `effect` string into concrete mutations on GameState.
///
/// Mirrors legacy-kotlin/.../CardResolver.kt case-by-case so the Dart
/// engine produces the same card outcomes as the Kotlin reference for
/// the same seed.
library;

import 'package:realita_engine/src/card_def.dart';
import 'package:realita_engine/src/game_engine.dart';
import 'package:realita_engine/src/game_event.dart';
import 'package:realita_engine/src/game_state.dart';
import 'package:realita_engine/src/models.dart';

class CardResolver {
  final GameEngine engine;
  const CardResolver(this.engine);

  /// Effect IDs that always require a player decision before resolving.
  static const Set<String> choiceCards = {
    'EVENT_MBG_TENDER',
    'EVENT_PARTY_DOWRY_OFFER',
    'EVENT_PORK_BARREL',
    'EVENT_PRIVATE_SCHOOL_FEE',
    'EVENT_RELATIVE_NEEDS_HELP',
    'EVENT_GAMBLING_AD',
    'EVENT_SIDE_BUSINESS',
    'EVENT_BRIBE_OFFER',
    'EVENT_VOTER_HANDOUT',
  };

  bool needsChoice(CardDef card) => choiceCards.contains(card.effect);

  /// Choices for a given effect — used by UI to render buttons.
  static List<String> choicesFor(String effect) {
    switch (effect) {
      case 'EVENT_MBG_TENDER':
        return ['skim', 'decline'];
      case 'EVENT_PARTY_DOWRY_OFFER':
        return ['clean', 'corrupt', 'decline'];
      case 'EVENT_PORK_BARREL':
        return ['corrupt', 'clean'];
      case 'EVENT_PRIVATE_SCHOOL_FEE':
        return ['private', 'public'];
      case 'EVENT_RELATIVE_NEEDS_HELP':
        return ['help', 'refuse'];
      case 'EVENT_GAMBLING_AD':
        return ['join', 'ignore'];
      case 'EVENT_SIDE_BUSINESS':
        return ['start', 'decline'];
      case 'EVENT_BRIBE_OFFER':
        return ['accept', 'decline'];
      case 'EVENT_VOTER_HANDOUT':
        return ['accept', 'refuse'];
    }
    return [];
  }

  /// Resolve a card that requires NO player choice.
  List<GameEvent> resolveImmediate(
      GameState state, int playerIdx, CardDef card) {
    final p = state.players[playerIdx];
    final ev = <GameEvent>[];
    final balance = engine.balance;

    double badLuckAdjusted(double amount) {
      if (p.cash >= balance.savingsBufferThreshold &&
          card.id.startsWith('BL')) {
        return amount * (1.0 - balance.badLuckCashReductionPct);
      }
      return amount;
    }

    void cash(double delta, String reason) {
      p.cash += delta;
      ev.add(CashDelta(playerIdx, delta, reason));
    }

    void h(int delta, String reason) {
      p.happiness += delta;
      ev.add(HappinessDelta(playerIdx, delta, reason));
    }

    void skip(int laps) {
      p.tokens.skipTurnLoss += laps;
      ev.add(SkipTurn(playerIdx, laps));
    }

    double insuranceHalved(double amount) =>
        p.insurance ? amount * 0.5 : amount;

    switch (card.effect) {
      // ---------- EVENTS ----------
      case 'EVENT_MBG_SKIMMED':
        if (p.children.isNotEmpty) {
          cash(-1.5, 'MBG clinic');
          h(-5, 'MBG clinic');
        }

      case 'EVENT_EMPTY_SPEECHES':
        for (var i = 0; i < state.players.length; i++) {
          state.players[i].happiness -= 10;
          ev.add(HappinessDelta(i, -10, 'Empty speeches'));
        }

      case 'EVENT_TRAPPED_IN_PINJOL':
        if (p.cash < 0 || p.cash < balance.baseLivingCostPerLap) {
          const principal = 3.0;
          p.pinjolDebt += principal;
          p.cash += principal;
          ev.add(
              LoanTaken(playerIdx, principal, balance.pinjolInterestPerLapPct));
        }

      case 'EVENT_KONDANGAN_MUDIK':
        cash(-1.5, 'Kondangan');
        skip(1);

      case 'EVENT_FUEL_SUBSIDY_REMOVED':
        if (p.career == Career.ojolDriver || p.career == Career.dailyWorker) {
          p.fuelSubsidyExtraPerRoll = balance.fuelSubsidyExtraPerRoll;
          p.fuelSubsidyLapsLeft = balance.fuelSubsidyLaps;
          ev.add(DebtFlagged(playerIdx, 'fuel_subsidy_on'));
        } else {
          cash(-0.5, 'Fuel price shock');
        }

      case 'EVENT_TAPERA_LOCKED':
        if (p.career == Career.pns || p.career == Career.scbdEmployee) {
          h(-3, 'TAPERA');
        }

      case 'EVENT_PPN_RECEIPT_SHOCK':
        for (var i = 0; i < state.players.length; i++) {
          state.players[i].cash -= 1.0;
          state.players[i].happiness -= 3;
          ev.add(CashDelta(i, -1.0, 'PPN shock'));
          ev.add(HappinessDelta(i, -3, 'PPN shock'));
        }

      case 'EVENT_KPK_STING':
        if (p.career == Career.politicianCorrupt) {
          ev.addAll(engine.rollKpkSting(state, playerIdx));
        } else {
          h(5, 'Clean conscience');
        }

      case 'EVENT_GIG_CUTS_RATES':
        if (p.career == Career.ojolDriver) {
          cash(-2.0, 'Aplikator cuts');
        }

      case 'EVENT_MASS_LAYOFFS':
        if (p.career == Career.scbdEmployee) {
          p.skipsNextPayday = true;
          ev.add(DebtFlagged(playerIdx, 'phk'));
        }

      case 'EVENT_OFFICE_EFFICIENCY':
        if (p.career == Career.pns) {
          cash(-1.5, 'Office efficiency');
          h(-3, 'Office efficiency');
        }

      case 'EVENT_PROPERTY_TAX':
        for (final a in p.assets) {
          final tax = a.price * 0.01;
          p.cash -= tax;
          ev.add(CashDelta(playerIdx, -tax, 'PBB on ${a.id}'));
        }

      case 'EVENT_MORTGAGE_RATE_RESET':
        for (final a in p.assets) {
          if (a.hasKpr) a.kprInterestBoostLapsLeft = 2;
        }
        ev.add(DebtFlagged(playerIdx, 'kpr_rate_reset'));

      case 'EVENT_BPJS_QUEUE':
        if (!p.insurance) {
          skip(1);
          h(-2, 'BPJS queue');
        }

      case 'EVENT_COMMUNITY_CLEANUP':
        h(5, 'Kerja bakti');

      case 'EVENT_PURCHASING_POWER_DROP':
        final c = p.career;
        if (c != null) {
          final loss = c.grossPayday * 0.10;
          cash(-loss, 'Purchasing power drop');
        }

      case 'EVENT_CHILD_TOPS_CLASS':
        if (p.children.isNotEmpty) h(8, 'Child tops class');

      case 'EVENT_HOME_REPAIR_AID':
        if (p.assets.any((a) => a.id == 'kampung_house')) {
          cash(2.0, 'Bedah rumah');
        }

      case 'EVENT_ROASTED_BY_NETIZENS':
        if (p.career?.isPolitician == true) {
          h(-8, 'Roasted by netizens');
        } else {
          h(-2, 'Roasted by netizens');
        }

      case 'EVENT_DEBT_FREE_BONUS':
        if (p.hasNoDebt) {
          cash(1.0, 'Debt-free bonus');
          h(4, 'Debt-free bonus');
        }

      case 'EVENT_COST_OF_LIVING_SQUEEZE':
        for (var i = 0; i < state.players.length; i++) {
          final q = state.players[i];
          final extra = q.livingCostThisLap(
              balance.baseLivingCostPerLap, balance.perChildLivingCost);
          q.cash -= extra;
          ev.add(CashDelta(i, -extra, 'Cost-of-living squeeze'));
          if (q.cash < balance.savingsBufferThreshold) {
            q.happiness -= 2;
            ev.add(HappinessDelta(i, -2, 'No savings buffer'));
          }
        }

      // ---------- GOOD LUCK ----------
      case 'GL_CASH_IN_JACKET':
        cash(1.0, 'Old jacket');

      case 'GL_SIDE_HUSTLE_VIRAL':
        cash(3.0, 'Viral side hustle');
        h(5, 'Viral side hustle');

      case 'GL_NEIGHBOR_REPAYS':
        cash(2.0, 'Neighbor repays');

      case 'GL_FREE_CHECKUP':
        h(5, 'Puskesmas');
        p.tokens.clinicCostCancel += 1;
        ev.add(TokenAwarded(playerIdx, 'cancel_clinic'));

      case 'GL_LUCKY_ARISAN':
        cash(5.0, 'Arisan win');

      case 'GL_GOTONG_ROYONG':
        p.tokens.cancelNegativeEvent += 1;
        ev.add(TokenAwarded(playerIdx, 'cancel_event'));

      case 'GL_THR_ARRIVES':
        cash(4.0, 'THR');

      case 'GL_TOLL_PAID':
        p.tokens.skipTurnLoss += 1;
        ev.add(TokenAwarded(playerIdx, 'skip_turn_loss'));

      case 'GL_PAYDAY_PROMO':
        cash(1.0, 'Promo warung');
        h(3, 'Promo warung');

      case 'GL_SCHOLARSHIP':
        if (p.children.isNotEmpty) {
          p.tokens.waiveNextSchoolFee += 1;
          ev.add(TokenAwarded(playerIdx, 'waive_school_fee'));
        } else {
          cash(2.0, 'Scholarship cash');
        }

      case 'GL_OVERTIME_PAID':
        final c = p.career;
        final amount =
            (c == Career.ojolDriver || c == Career.dailyWorker) ? 2.0 : 3.0;
        cash(amount, 'Overtime paid');

      case 'GL_UNCLE_TREATS':
        h(8, 'Om traktir');

      case 'GL_TAX_REFUND':
        cash(3.0, 'Tax refund');

      case 'GL_CHEAP_RENTAL':
        p.cheapRentDiscountLapsLeft = 2;
        p.cheapRentDiscountPct = 0.50;
        ev.add(DebtFlagged(playerIdx, 'cheap_rent'));

      case 'GL_LOAN_WAIVER':
        if (p.hasPinjol) {
          final interest = p.pinjolDebt * balance.pinjolInterestPerLapPct;
          p.pinjolDebt = (p.pinjolDebt - interest).clamp(0.0, double.infinity);
          ev.add(CashDelta(playerIdx, interest, 'Pinjol interest waived'));
        } else {
          h(3, 'No loan to waive');
        }

      case 'GL_VILLAGE_RAFFLE':
        cash(2.0, 'Raffle prize');

      case 'GL_FRIEND_REFERRAL':
        ev.add(TokenAwarded(playerIdx, 'roll_again'));

      case 'GL_OJOL_BONUS':
        final amount = p.career == Career.ojolDriver ? 2.0 : 1.0;
        cash(amount, 'Ojol bonus');

      case 'GL_NEIGHBORS_PRAISE':
        final bonus = p.route == Route.clean ? 15 : 10;
        h(bonus, 'Warga memuji');

      case 'GL_HARVEST_FROM_HOME':
        cash(1.0, 'Kiriman kampung');
        h(4, 'Kiriman kampung');

      // ---------- BAD LUCK ----------
      case 'BL_MOTOR_BREAKDOWN':
        cash(-badLuckAdjusted(2.0), 'Motor mogok');

      case 'BL_PHONE_SNATCHED':
        cash(-badLuckAdjusted(3.0), 'HP dijambret');
        h(-5, 'HP dijambret');

      case 'BL_FLOOD':
        cash(-badLuckAdjusted(2.0), 'Banjir');
        skip(1);

      case 'BL_OVERTIME_UNPAID':
        cash(-badLuckAdjusted(2.0), 'Lembur tak dibayar');

      case 'BL_FAKE_SHOP':
        cash(-badLuckAdjusted(3.0), 'Toko online palsu');

      case 'BL_HOSPITAL_BILL':
        cash(-insuranceHalved(badLuckAdjusted(8.0)), 'Tagihan RS');

      case 'BL_RENT_RAISE':
        p.landlordRentExtraLapsLeft = 2;
        p.landlordRentExtraPerLap = 1.0;
        ev.add(DebtFlagged(playerIdx, 'rent_raise'));

      case 'BL_VIRAL_AIB':
        h(-8, 'Aib viral');

      case 'BL_FUEL_QUEUE':
        skip(1);
        if (p.career == Career.ojolDriver) cash(-2.0, 'Antre BBM');

      case 'BL_LPG_SHORTAGE':
        cash(-1.0, 'Gas melon langka');
        h(-3, 'Gas melon langka');

      case 'BL_CONTRACT_NOT_RENEWED':
        if (p.career != Career.pns && p.career?.isPolitician != true) {
          p.skipsNextPayday = true;
          ev.add(DebtFlagged(playerIdx, 'contract_not_renewed'));
        }

      case 'BL_WEDDING_INVITES':
        cash(-2.0, 'Undangan nikahan');
        h(-3, 'Undangan nikahan');

      case 'BL_SCHOOL_FEE_HIKE':
        final amount = p.children.isNotEmpty ? 4.0 : 1.0;
        cash(-badLuckAdjusted(amount), 'Uang gedung');

      case 'BL_BLACKOUT_FRIDGE':
        cash(-1.0, 'Listrik padam');

      case 'BL_TRAFFIC_TICKET':
        cash(-1.0, 'Ditilang');

      case 'BL_DENGUE':
        final amount = insuranceHalved(badLuckAdjusted(3.0));
        cash(-amount, 'Demam berdarah');
        h(-5, 'Demam berdarah');

      case 'BL_DEBT_COLLECTOR':
        h(p.hasPinjol ? -8 : -2, 'Debt collector');

      case 'BL_ROOF_LEAK':
        cash(-badLuckAdjusted(2.0), 'Atap bocor');

      case 'BL_RICE_OIL_SPIKE':
        for (var i = 0; i < state.players.length; i++) {
          state.players[i].cash -= 2.0;
          ev.add(CashDelta(i, -2.0, 'Harga beras/minyak naik'));
        }

      case 'BL_FRIEND_DISAPPEARS':
        cash(-2.0, 'Teman menghilang');
        h(-4, 'Teman menghilang');

      // Choice cards (E02, E09, E11, E12, E18, E20, E21, E22, E30) are
      // no-ops here — applyChoice() handles them after the player picks.
      default:
        break;
    }

    return ev;
  }

  /// Apply a player's choice for a choice card.
  List<GameEvent> applyChoice(
      GameState state, int playerIdx, CardDef card, String choice) {
    final p = state.players[playerIdx];
    final ev = <GameEvent>[];
    final balance = engine.balance;

    void cash(double delta, String reason) {
      p.cash += delta;
      ev.add(CashDelta(playerIdx, delta, reason));
    }

    void h(int delta, String reason) {
      p.happiness += delta;
      ev.add(HappinessDelta(playerIdx, delta, reason));
    }

    switch (card.effect) {
      case 'EVENT_MBG_TENDER':
        if (choice == 'skim') {
          cash(8.0, 'MBG tender skim');
          if (engine.rng.chance(0.35)) {
            cash(-12.0, 'Investigation fine');
            h(-15, 'Investigation');
            p.corruptFlagEver = true;
            p.route = Route.corrupt;
            ev.add(DebtFlagged(playerIdx, 'corrupt_flag'));
          }
        } else {
          h(5, 'Declined skim');
        }

      case 'EVENT_PARTY_DOWRY_OFFER':
        if (choice == 'clean' || choice == 'corrupt') {
          ev.addAll(engine.enterPoliticianPath(state, playerIdx,
              corrupt: choice == 'corrupt'));
        } else {
          h(2, 'Declined politics');
        }

      case 'EVENT_PORK_BARREL':
        if (choice == 'corrupt') {
          cash(10.0, 'Pork barrel');
          p.corruptionHeat += 2;
          p.corruptFlagEver = true;
          ev.add(DebtFlagged(playerIdx, 'heat_up'));
        } else {
          h(4, 'Clean pork barrel');
        }

      case 'EVENT_PRIVATE_SCHOOL_FEE':
        if (choice == 'private') {
          cash(-5.0, 'Private school fee');
          if (p.children.isNotEmpty) {
            final idx = p.children.length - 1;
            p.children[idx] =
                p.children[idx].copyWith(isFunded: true, isPrivateSchool: true);
          }
        } else {
          h(-3, 'Public school');
        }

      case 'EVENT_RELATIVE_NEEDS_HELP':
        if (choice == 'help') {
          cash(-2.0, 'Help saudara');
          h(4, 'Help saudara');
        } else {
          h(-4, 'Refuse saudara');
        }

      case 'EVENT_GAMBLING_AD':
        if (choice == 'join') {
          cash(-3.0, 'Judi online');
          h(-5, 'Judi online');
        } else {
          h(2, 'Tolak judi');
        }

      case 'EVENT_SIDE_BUSINESS':
        if (choice == 'start') {
          cash(-3.0, 'Side business start');
          if (engine.rng.chance(balance.sideBusinessFlopChance)) {
            ev.add(DebtFlagged(playerIdx, 'side_business_flop'));
          } else {
            p.sideBusinessLapsLeft = balance.sideBusinessLaps;
            p.sideBusinessIncomePerLap = balance.sideBusinessIncomePerLap;
            ev.add(DebtFlagged(playerIdx, 'side_business_on'));
          }
        }

      case 'EVENT_BRIBE_OFFER':
        if (choice == 'accept') {
          cash(4.0, 'Bribe accepted');
          h(-5, 'Bribe accepted');
          p.corruptFlagEver = true;
          p.corruptionHeat += 1;
          ev.add(DebtFlagged(playerIdx, 'corrupt_flag'));
        } else {
          h(3, 'Declined bribe');
        }

      case 'EVENT_VOTER_HANDOUT':
        if (choice == 'accept') {
          cash(0.5, 'Voter handout');
          h(-3, 'Voter handout');
          if (p.career == Career.politicianCorrupt) {
            p.corruptionHeat += 1;
            ev.add(DebtFlagged(playerIdx, 'heat_up'));
          }
        } else {
          h(3, 'Refused handout');
        }

      default:
        break;
    }

    return ev;
  }
}
