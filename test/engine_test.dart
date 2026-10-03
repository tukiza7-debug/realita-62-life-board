/// Unit tests for the Dart engine. Mirrors the legacy Kotlin test suite
/// method-by-method; verifies the same arithmetic as the Kotlin reference.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:realita_engine/realita_engine.dart';

void main() {
  GameEngine newEngine({int seed = 42}) =>
      GameEngine(BalanceConfig.defaultConfig, SeededRng(seed));

  Player newPlayer({Career? career, double cash = 5.0, int id = 0}) =>
      Player(id: id, name: 'P$id', career: career, cash: cash);

  GameState newState(Player p, {BalanceConfig? balance}) => GameState(
        seed: 42,
        players: [p],
        assetCatalogue: AssetCatalogue.defaultCatalogue,
      );

  // -------------------------------------------------------------------
  // PAYDAY
  // -------------------------------------------------------------------

  test('payday pays gross for Ojol Driver with no TAPERA', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.ojolDriver);
    final state = newState(p);
    engine.payday(state, 0);
    expect(p.cash, 5.0 + 4.0);
  });

  test('payday applies TAPERA 3% for PNS', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns);
    final state = newState(p);
    engine.payday(state, 0);
    // Gross 9, TAPERA 3% = 0.27, take-home = 8.73; cash starts 5.0.
    expect(p.cash, closeTo(5.0 + 8.73, 0.001));
  });

  test('payday applies TAPERA 3% for SCBD', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.scbdEmployee);
    final state = newState(p);
    engine.payday(state, 0);
    expect(p.cash, closeTo(5.0 + 11.64, 0.001));
  });

  test('payday skipped when player has skipsNextPayday flag', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns)
      ..skipsNextPayday = true
      ..cash = 0.0;
    final state = newState(p);
    engine.payday(state, 0);
    expect(p.cash, 0.0);
    expect(p.skipsNextPayday, false);
  });

  // -------------------------------------------------------------------
  // INTEREST
  // -------------------------------------------------------------------

  test('UKT interest is 2% per lap', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns)..uktDebt = 10.0;
    final state = newState(p);
    engine.endOfLap(state, 0);
    expect(p.uktDebt, closeTo(10.2, 0.001));
  });

  test('KPR interest is 3% per lap on remaining principal', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns)
      ..assets.add(
          Asset(id: 'apt', name: 'Apartment', price: 35.0, remainingKpr: 28.0));
    final state = newState(p);
    engine.endOfLap(state, 0);
    expect(p.assets[0].remainingKpr, closeTo(28.84, 0.001));
  });

  test('Pinjol interest is 15% per lap', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.dailyWorker)..pinjolDebt = 3.0;
    final state = newState(p);
    engine.endOfLap(state, 0);
    expect(p.pinjolDebt, closeTo(3.45, 0.001));
  });

  // -------------------------------------------------------------------
  // PPN 12%
  // -------------------------------------------------------------------

  test('asset purchase applies PPN 12% and 20% down payment', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.scbdEmployee, cash: 20.0);
    final state = newState(p);
    final result = engine.purchaseAsset(state, 0, 'apartment');
    expect(result.ok, true);
    expect(result.downPayment, closeTo(7.84, 0.001));
    expect(result.kprPrincipal, closeTo(31.36, 0.001));
    expect(p.cash, closeTo(20.0 - 7.84, 0.001));
    expect(p.assets[0].remainingKpr, closeTo(31.36, 0.001));
  });

  test('asset purchase fails when cash is insufficient', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.ojolDriver, cash: 1.0);
    final state = newState(p);
    final result = engine.purchaseAsset(state, 0, 'menteng_mansion');
    expect(result.ok, false);
  });

  // -------------------------------------------------------------------
  // FUEL SUBSIDY (event E06)
  // -------------------------------------------------------------------

  test('fuel subsidy timer ticks down each lap', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.ojolDriver)
      ..fuelSubsidyLapsLeft = 3
      ..fuelSubsidyExtraPerRoll = 0.2;
    final state = newState(p);
    for (var i = 0; i < 3; i++) {
      engine.endOfLap(state, 0);
    }
    expect(p.fuelSubsidyLapsLeft, 0);
    expect(p.fuelSubsidyExtraPerRoll, 0.0);
  });

  // -------------------------------------------------------------------
  // SCORING
  // -------------------------------------------------------------------

  test('clean player score = netAssets + cash + (H * 0.5M)', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns, cash: 10.0)
      ..happiness = 10
      ..assets.add(
          Asset(id: 'apt', name: 'Apartment', price: 35.0, remainingKpr: 0.0));
    // 35 + 10 + (10 * 0.5) + 0 = 50
    expect(engine.finalScore(p), 50.0);
  });

  test('corrupt player with negative H has score halved', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.politicianCorrupt, cash: 50.0)
      ..happiness = -5
      ..corruptFlagEver = true;
    // 0 + 50 + (-5 * 0.5) = 47.5, halved = 23.75
    expect(engine.finalScore(p), closeTo(23.75, 0.001));
  });

  test('corrupt player with positive H keeps full score', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.politicianCorrupt, cash: 50.0)
      ..happiness = 5
      ..corruptFlagEver = true;
    // 50 + (5 * 0.5) = 52.5
    expect(engine.finalScore(p), closeTo(52.5, 0.001));
  });

  test('Warga Teladan: no corruption, no Pinjol, positive H, Jogja/Bali', () {
    final engine = newEngine();
    final pClean = newPlayer(career: Career.pns, cash: 10.0)
      ..happiness = 5
      ..retirement = RetirementChoice.kampungJogja;
    expect(engine.isWargaTeladan(pClean), true);

    final pPinjol = pClean..pinjolDebt = 1.0;
    expect(engine.isWargaTeladan(pPinjol), false);

    final pMenteng = newPlayer(career: Career.pns, cash: 10.0)
      ..happiness = 5
      ..retirement = RetirementChoice.eliteMenteng;
    expect(engine.isWargaTeladan(pMenteng), false);

    final pNeg = newPlayer(career: Career.pns, cash: 10.0)
      ..happiness = -1
      ..retirement = RetirementChoice.kampungJogja;
    expect(engine.isWargaTeladan(pNeg), false);
  });

  // -------------------------------------------------------------------
  // DYNASTY LEGACY
  // -------------------------------------------------------------------

  test('funded child adds 3M, unfunded adds 0.5M', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.pns, cash: 0.0)
      ..children.add(Child(id: 'c1', isFunded: true))
      ..children.add(Child(id: 'c2', isFunded: false));
    // 0 + 0 + 0 + 3.5 = 3.5
    expect(engine.finalScore(p), closeTo(3.5, 0.001));
  });

  test('nepotism perk halves funded legacy bonus', () {
    final engine = newEngine();
    final p = newPlayer(career: Career.politicianClean, cash: 0.0)
      ..children.add(Child(id: 'c1', isFunded: true))
      ..usedNepotismPerk = true;
    // 3 * 0.5 = 1.5
    expect(engine.finalScore(p), closeTo(1.5, 0.001));
  });

  // -------------------------------------------------------------------
  // SAVE / LOAD
  // -------------------------------------------------------------------

  test('game state serializes and round-trips back', () {
    final p = newPlayer(career: Career.ojolDriver, cash: 7.0)
      ..uktDebt = 0.0
      ..happiness = 3;
    final state = newState(p);
    final j = _stateToJson(state);
    final restored = _stateFromJson(j);
    expect(restored.seed, state.seed);
    expect(restored.players.length, 1);
    expect(restored.players[0].cash, 7.0);
    expect(restored.players[0].happiness, 3);
  });

  // -------------------------------------------------------------------
  // DETERMINISTIC RNG
  // -------------------------------------------------------------------

  test('same seed produces same dice sequence', () {
    final a = SeededRng(123);
    final b = SeededRng(123);
    for (var i = 0; i < 50; i++) {
      expect(a.rollDice(), b.rollDice());
    }
  });

  test('string seed is reproducible', () {
    final a = SeededRng.fromStringSeed('realita-62-test');
    final b = SeededRng.fromStringSeed('realita-62-test');
    for (var i = 0; i < 100; i++) {
      expect(a.nextInt(60), b.nextInt(60));
    }
  });

  // -------------------------------------------------------------------
  // CARD TESTS (one per representative category)
  // -------------------------------------------------------------------

  CardDef card(String id, String effect, {bool isLuck = false}) => CardDef(
        id: id,
        titleEn: '',
        titleId: '',
        flavorEn: '',
        flavorId: '',
        effect: effect,
        isLuck: isLuck,
      );

  test('EVENT_FUEL_SUBSIDY_REMOVED applies to Ojol and Daily Worker only', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final balance = BalanceConfig.defaultConfig;
    final c = card('E06', 'EVENT_FUEL_SUBSIDY_REMOVED');

    final ojol = newPlayer(career: Career.ojolDriver, cash: 5.0);
    final st = newState(ojol);
    resolver.resolveImmediate(st, 0, c);
    expect(ojol.fuelSubsidyLapsLeft, balance.fuelSubsidyLaps);
    expect(ojol.fuelSubsidyExtraPerRoll, balance.fuelSubsidyExtraPerRoll);

    final pns = newPlayer(career: Career.pns, cash: 5.0);
    final st2 = newState(pns);
    resolver.resolveImmediate(st2, 0, c);
    expect(pns.cash, closeTo(4.5, 0.001));
  });

  test('GL_NEIGHBORS_PRAISE gives 15H to clean route, 10H otherwise', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('GL19', 'GL_NEIGHBORS_PRAISE', isLuck: true);

    final clean = newPlayer(career: Career.pns)..route = Route.clean;
    resolver.resolveImmediate(newState(clean), 0, c);
    expect(clean.happiness, 15);

    final none = newPlayer(career: Career.pns);
    resolver.resolveImmediate(newState(none), 0, c);
    expect(none.happiness, 10);
  });

  test('BL_HOSPITAL_BILL is halved when player is insured', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('BL06', 'BL_HOSPITAL_BILL', isLuck: true);
    final insured = newPlayer(career: Career.pns, cash: 5.0)..insurance = true;
    resolver.resolveImmediate(newState(insured), 0, c);
    expect(insured.cash, 5.0 - 4.0);

    final uninsured = newPlayer(career: Career.pns, cash: 5.0);
    resolver.resolveImmediate(newState(uninsured), 0, c);
    expect(uninsured.cash, 5.0 - 8.0);
  });

  test('EVENT_DEBT_FREE_BONUS gives 4H and 1M cash when no debt', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('E28', 'EVENT_DEBT_FREE_BONUS');
    final p = newPlayer(career: Career.pns, cash: 5.0);
    resolver.resolveImmediate(newState(p), 0, c);
    expect(p.cash, 6.0);
    expect(p.happiness, 4);

    final indebted = newPlayer(career: Career.pns, cash: 5.0)..pinjolDebt = 1.0;
    resolver.resolveImmediate(newState(indebted), 0, c);
    expect(indebted.cash, 5.0);
    expect(indebted.happiness, 0);
  });

  test('EVENT_MBG_TENDER skim has ~35% investigation chance', () {
    var investigations = 0;
    for (var i = 0; i < 1000; i++) {
      final engine = newEngine(seed: i);
      final resolver = CardResolver(engine);
      final c = card('E02', 'EVENT_MBG_TENDER');
      final p = newPlayer(career: Career.contractor, cash: 50.0);
      resolver.applyChoice(newState(p), 0, c, 'skim');
      if (p.corruptFlagEver) investigations += 1;
    }
    expect(investigations, inInclusiveRange(250, 450));
  });

  test('EVENT_EMPTY_SPEECHES hits all players with -10H', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('E03', 'EVENT_EMPTY_SPEECHES');
    final p1 = newPlayer(career: Career.pns, cash: 5.0, id: 0);
    final p2 = newPlayer(career: Career.ojolDriver, cash: 5.0, id: 1);
    final state = GameState(seed: 42, players: [p1, p2]);
    resolver.resolveImmediate(state, 0, c);
    expect(p1.happiness, -10);
    expect(p2.happiness, -10);
  });

  test('EVENT_COST_OF_LIVING_SQUEEZE applies one extra living cost', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('E29', 'EVENT_COST_OF_LIVING_SQUEEZE');
    final p = newPlayer(career: Career.pns, cash: 20.0);
    resolver.resolveImmediate(newState(p), 0, c);
    expect(p.cash, lessThan(20.0));
  });

  test('BL_RICE_OIL_SPIKE applies to all players', () {
    final engine = newEngine();
    final resolver = CardResolver(engine);
    final c = card('BL19', 'BL_RICE_OIL_SPIKE', isLuck: true);
    final p1 = newPlayer(career: Career.pns, cash: 10.0, id: 0);
    final p2 = newPlayer(career: Career.ojolDriver, cash: 10.0, id: 1);
    final state = GameState(seed: 42, players: [p1, p2]);
    resolver.resolveImmediate(state, 0, c);
    expect(p1.cash, 8.0);
    expect(p2.cash, 8.0);
  });

  // -------------------------------------------------------------------
  // KPK STING
  // -------------------------------------------------------------------

  test('KPK sting chance equals heat * 10%', () {
    var catches = 0;
    for (var i = 0; i < 1000; i++) {
      final engine = newEngine(seed: i);
      final p = newPlayer(career: Career.politicianCorrupt, cash: 20.0)
        ..corruptionHeat = 0;
      engine.rollKpkSting(newState(p), 0);
      if (p.cash < 20.0) catches += 1;
    }
    expect(catches, 0); // heat 0 → 0% chance
  });

  test('KPK sting catches corrupt players proportional to heat', () {
    var catches = 0;
    for (var i = 0; i < 100; i++) {
      final engine = newEngine(seed: i);
      final p = newPlayer(career: Career.politicianCorrupt, cash: 20.0)
        ..corruptionHeat = 10;
      engine.rollKpkSting(newState(p), 0);
      if (p.cash < 20.0) catches += 1;
    }
    expect(catches, 100); // heat 10 → 100% chance
  });
}

// ----------------------- helpers for save/load round-trip ----------------

Map<String, dynamic> _stateToJson(GameState state) => {
      'seed': state.seed,
      'players': state.players.map((p) => p.toJson()).toList(),
      'turn': state.turn,
      'currentPlayerIdx': state.currentPlayerIdx,
      'gameOver': state.gameOver,
      'drawnEvents': state.drawnEvents,
      'drawnLuck': state.drawnLuck,
      'goodLuckDrawsThisLap': state.goodLuckDrawsThisLap,
      'schemaVersion': 1,
    };

GameState _stateFromJson(Map<String, dynamic> j) {
  final players = (j['players'] as List)
      .map((p) => Player.fromJson(p as Map<String, dynamic>))
      .toList();
  return GameState(
    seed: (j['seed'] as num).toInt(),
    players: players,
    turn: (j['turn'] as num?)?.toInt() ?? 0,
    currentPlayerIdx: (j['currentPlayerIdx'] as num?)?.toInt() ?? 0,
    gameOver: j['gameOver'] as bool? ?? false,
    drawnEvents: (j['drawnEvents'] as List?)?.cast<String>() ?? [],
    drawnLuck: (j['drawnLuck'] as List?)?.cast<String>() ?? [],
    goodLuckDrawsThisLap: (j['goodLuckDrawsThisLap'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        List.filled(players.length, 0),
  );
}
