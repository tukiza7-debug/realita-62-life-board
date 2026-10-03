/// Deterministic rules engine. Pure Dart, ZERO Flutter imports. Mirrors
/// legacy-kotlin/.../GameEngine.kt method-by-method so the same seed
/// produces the same game.
library;

import 'package:realita_engine/src/balance_config.dart';
import 'package:realita_engine/src/game_event.dart';
import 'package:realita_engine/src/game_state.dart';
import 'package:realita_engine/src/models.dart';
import 'package:realita_engine/src/seeded_rng.dart';

class PurchaseResult {
  final double? downPayment;
  final double? kprPrincipal;
  final Asset? asset;
  final String? failureReason;
  const PurchaseResult._ok(this.downPayment, this.kprPrincipal, this.asset)
      : failureReason = null;
  const PurchaseResult._failed(this.failureReason)
      : downPayment = null,
        kprPrincipal = null,
        asset = null;

  bool get ok => failureReason == null;

  factory PurchaseResult.ok(double down, double kpr, Asset asset) =>
      PurchaseResult._ok(down, kpr, asset);
  factory PurchaseResult.failed(String reason) =>
      PurchaseResult._failed(reason);
}

class GameEngine {
  final BalanceConfig balance;
  final SeededRng rng;

  GameEngine(this.balance, this.rng);

  // -------------------------------------------------------------------
  // PAYDAY
  // -------------------------------------------------------------------

  /// Resolve a payday tile. Mirrors Kotlin `payday()`.
  List<GameEvent> payday(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    final events = <GameEvent>[];

    if (p.skipsNextPayday) {
      p.skipsNextPayday = false;
      events.add(PaydaySkipped(playerIdx));
      return events;
    }

    final career = p.career;
    if (career == null) return events;

    var gross = career.grossPayday;

    if (p.sideBusinessLapsLeft > 0) {
      gross += p.sideBusinessIncomePerLap;
      events.add(SideBusinessPaid(playerIdx, p.sideBusinessIncomePerLap));
    }

    var taperaDeduction = 0.0;
    if (career == Career.pns || career == Career.scbdEmployee) {
      taperaDeduction = gross * balance.taperaPct;
      gross -= taperaDeduction;
    }

    p.cash += gross;
    events.add(Payday(playerIdx, career, gross, taperaDeduction));
    return events;
  }

  // -------------------------------------------------------------------
  // END-OF-LAP
  // -------------------------------------------------------------------

  /// Apply per-lap costs. Mirrors Kotlin `endOfLap()`.
  List<GameEvent> endOfLap(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    final events = <GameEvent>[];

    // 1. Living cost
    final living = p.livingCostThisLap(
        balance.baseLivingCostPerLap, balance.perChildLivingCost);
    if (living > 0) {
      p.cash -= living;
      events.add(LivingCost(playerIdx, living));
    }

    // 2. UKT interest
    if (p.uktDebt > 0.001) {
      final interest = p.uktDebt * balance.uktInterestPerLapPct;
      p.uktDebt += interest;
      events.add(UktInterest(playerIdx, interest));
    }

    // 3. KPR interest per asset
    for (final asset in p.assets) {
      if (!asset.hasKpr) continue;
      final rate = balance.kprInterestBasePerLapPct +
          (asset.kprInterestBoostLapsLeft > 0 ? 0.01 : 0.0);
      final interest = asset.remainingKpr * rate;
      asset.remainingKpr =
          (asset.remainingKpr + interest).clamp(0.0, double.infinity);
      if (asset.kprInterestBoostLapsLeft > 0) {
        asset.kprInterestBoostLapsLeft -= 1;
      }
      events.add(KprInterest(playerIdx, asset.id, interest));
    }

    // 4. Pinjol interest
    if (p.pinjolDebt > 0.001) {
      final interest = p.pinjolDebt * balance.pinjolInterestPerLapPct;
      p.pinjolDebt += interest;
      p.pinjolInterestNextLap = p.pinjolDebt * balance.pinjolInterestPerLapPct;
      events.add(PinjolInterest(playerIdx, interest));
    } else {
      p.pinjolInterestNextLap = 0.0;
    }

    // 5. Fuel subsidy timer
    if (p.fuelSubsidyLapsLeft > 0) {
      p.fuelSubsidyLapsLeft -= 1;
      if (p.fuelSubsidyLapsLeft == 0) {
        p.fuelSubsidyExtraPerRoll = 0.0;
        events.add(FuelSubsidyEnded(playerIdx));
      }
    }

    // 6. Side business timer
    if (p.sideBusinessLapsLeft > 0) {
      p.sideBusinessLapsLeft -= 1;
      if (p.sideBusinessLapsLeft == 0) {
        p.sideBusinessIncomePerLap = 0.0;
        events.add(SideBusinessEnded(playerIdx));
      }
    }

    // 7. Landlord extra-rent timer
    if (p.landlordRentExtraLapsLeft > 0) {
      p.landlordRentExtraLapsLeft -= 1;
      if (p.landlordRentExtraLapsLeft == 0) {
        p.landlordRentExtraPerLap = 0.0;
        events.add(LandlordRentEnded(playerIdx));
      }
    }

    // 8. Cheap-rent discount timer
    if (p.cheapRentDiscountLapsLeft > 0) {
      p.cheapRentDiscountLapsLeft -= 1;
      if (p.cheapRentDiscountLapsLeft == 0) {
        p.cheapRentDiscountPct = 0.0;
        events.add(CheapRentEnded(playerIdx));
      }
    }

    p.lapsCompleted += 1;
    return events;
  }

  // -------------------------------------------------------------------
  // ASSET PURCHASE
  // -------------------------------------------------------------------

  /// Purchase an asset with 12% PPN, 20% down, 80% KPR. Mirrors Kotlin
  /// `purchaseAsset()`.
  PurchaseResult purchaseAsset(GameState state, int playerIdx, String assetId) {
    final p = state.players[playerIdx];
    final def = state.assetCatalogue.items
        .cast<AssetDef?>()
        .firstWhere((d) => d!.id == assetId, orElse: () => null);
    if (def == null) {
      return PurchaseResult.failed('Unknown asset $assetId');
    }

    final priceWithPpn = def.price * (1.0 + balance.ppnPct);
    final down = priceWithPpn * 0.20;
    if (p.cash < down) {
      return PurchaseResult.failed(
          'Not enough cash for down payment (Rp ${down}M)');
    }
    p.cash -= down;
    final kpr = priceWithPpn * 0.80;
    final asset = Asset(
      id: def.id,
      name: def.nameEn,
      price: def.price,
      remainingKpr: kpr,
      kprInterestBase: def.kprInterestBasePerLapPct,
    );
    p.assets.add(asset);
    return PurchaseResult.ok(down, kpr, asset);
  }

  // -------------------------------------------------------------------
  // CORRUPTION
  // -------------------------------------------------------------------

  /// Politician Corrupt: steal project funds.
  List<GameEvent> stealProjectFunds(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    if (p.career != Career.politicianCorrupt) return [];
    final amount = balance.enterCorruptTheftPerLap;
    p.cash += amount;
    p.corruptionHeat += balance.enterCorruptHeatPerTheft;
    p.corruptFlagEver = true;
    return [StoleProjectFunds(playerIdx, amount, p.corruptionHeat)];
  }

  /// KPK sting check.
  List<GameEvent> rollKpkSting(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    if (p.career != Career.politicianCorrupt) return [];
    final chance =
        (p.corruptionHeat * balance.kpkStingChancePerHeatPct).clamp(0.0, 1.0);
    if (!rng.chance(chance)) {
      return [KpkStingMiss(playerIdx)];
    }
    final cashLoss = p.cash * balance.kpkStingCaughtCashLossPct;
    p.cash -= cashLoss;
    p.happiness -= balance.kpkStingCaughtHeatLoss;
    p.skipsNextTurn = true;
    p.tokens.skipTurnLoss += 1;
    p.corruptionHeat = (p.corruptionHeat ~/ 2).clamp(0, 1 << 30);
    return [KpkStingCaught(playerIdx, cashLoss)];
  }

  // -------------------------------------------------------------------
  // SCORING
  // -------------------------------------------------------------------

  double finalScore(Player p) {
    final legacyBonus = _computeLegacyBonus(p);
    var score = p.netAssets() +
        (p.cash < 0 ? 0.0 : p.cash) +
        (p.happiness * balance.happinessValueInScore) +
        legacyBonus;
    if (p.corruptFlagEver &&
        p.happiness < balance.corruptRouteFinalHappinessThreshold) {
      score = score / balance.corruptRouteFinalScoreDivider.toDouble();
    }
    return score;
  }

  double _computeLegacyBonus(Player p) {
    var funded = 0.0;
    var unfunded = 0.0;
    for (final c in p.children) {
      if (c.isFunded) {
        funded += balance.legacyPerFundedChild;
      } else {
        unfunded += balance.legacyPerUnfundedChild;
      }
    }
    if (p.usedNepotismPerk) funded *= 0.5;
    return funded + unfunded;
  }

  bool isWargaTeladan(Player p) =>
      !p.corruptFlagEver &&
      !p.hasPinjol &&
      p.happiness > 0 &&
      (p.retirement == RetirementChoice.kampungJogja ||
          p.retirement == RetirementChoice.islandBali);

  // -------------------------------------------------------------------
  // FAMILY
  // -------------------------------------------------------------------

  List<GameEvent> marry(GameState state, int playerIdx, bool lavish) {
    final p = state.players[playerIdx];
    if (lavish) {
      p.cash -= balance.lavishWeddingCost;
      if (p.cash < 0) {
        p.pinjolDebt += -p.cash;
        p.cash = 0.0;
      }
      p.maritalStatus = MaritalStatus.marriedLavish;
      p.happiness += balance.lavishWeddingHappiness;
      return [
        Married(playerIdx, true, balance.lavishWeddingCost,
            balance.lavishWeddingHappiness)
      ];
    } else {
      p.cash -= balance.modestWeddingCost;
      p.maritalStatus = MaritalStatus.marriedModest;
      p.happiness += balance.modestWeddingHappiness;
      return [
        Married(playerIdx, false, balance.modestWeddingCost,
            balance.modestWeddingHappiness)
      ];
    }
  }

  List<GameEvent> addChild(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    final c = Child(id: 'c-${p.children.length + 1}-${state.turn}');
    p.children.add(c);
    return [ChildBorn(playerIdx, c.id)];
  }

  List<GameEvent> fundChildSchool(
      GameState state, int playerIdx, int childIdx, bool privateSchool) {
    final p = state.players[playerIdx];
    if (childIdx < 0 || childIdx >= p.children.length) return [];
    final cost = privateSchool ? 5.0 : 1.5;
    p.cash -= cost;
    final c = p.children[childIdx];
    p.children[childIdx] =
        c.copyWith(isFunded: true, isPrivateSchool: privateSchool);
    return [SchoolFunded(playerIdx, childIdx, privateSchool, cost)];
  }

  // -------------------------------------------------------------------
  // POLITICIAN PATH
  // -------------------------------------------------------------------

  List<GameEvent> enterPoliticianPath(GameState state, int playerIdx,
      {required bool corrupt}) {
    final p = state.players[playerIdx];
    if (p.cash < balance.partyDowry) {
      return [PoliticianEntryFailed(playerIdx, 'Not enough cash')];
    }
    p.cash -= balance.partyDowry;
    p.career = corrupt ? Career.politicianCorrupt : Career.politicianClean;
    p.route = corrupt ? Route.corrupt : Route.clean;
    if (corrupt) p.corruptFlagEver = true;
    return [EnteredPoliticianPath(playerIdx, corrupt, balance.partyDowry)];
  }

  List<GameEvent> nepotismPerk(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    if (p.career?.isPolitician != true) return [];
    const gain = 4.0;
    p.cash += gain;
    p.happiness -= 6;
    p.usedNepotismPerk = true;
    return [NepotismPerk(playerIdx, gain)];
  }

  // -------------------------------------------------------------------
  // RETIREMENT
  // -------------------------------------------------------------------

  List<GameEvent> retire(
      GameState state, int playerIdx, RetirementChoice choice) {
    final p = state.players[playerIdx];
    p.retired = true;
    p.retirement = choice;
    final score = finalScore(p);
    return [Retired(playerIdx, choice, score, isWargaTeladan(p))];
  }

  bool isGameOver(GameState state) => state.players.every((p) => p.retired);
}
