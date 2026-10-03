/// Card deck + movement logic. Mirrors legacy-kotlin/.../CardDeck.kt
/// and Movement.kt so the same seed produces the same draw sequence
/// and the same pawn hops.
library;

import 'package:realita_engine/src/balance_config.dart';
import 'package:realita_engine/src/board.dart';
import 'package:realita_engine/src/card_def.dart';
import 'package:realita_engine/src/game_engine.dart';
import 'package:realita_engine/src/game_event.dart';
import 'package:realita_engine/src/game_state.dart';
import 'package:realita_engine/src/seeded_rng.dart';

class CardDeck {
  final GameEngine engine;
  final CardLibrary library;
  List<CardDef> _eventPile;
  List<CardDef> _goodLuckPile;
  List<CardDef> _badLuckPile;

  CardDeck(this.engine, this.library)
      : _eventPile = [],
        _goodLuckPile = [],
        _badLuckPile = [] {
    reshuffle();
  }

  void reshuffle() {
    _eventPile = List.of(library.events);
    engine.rng.shuffle(_eventPile);
    _goodLuckPile = List.of(library.goodLuck);
    engine.rng.shuffle(_goodLuckPile);
    _badLuckPile = List.of(library.badLuck);
    engine.rng.shuffle(_badLuckPile);
  }

  CardDef drawEvent() {
    if (_eventPile.isEmpty) {
      _eventPile = List.of(library.events);
      engine.rng.shuffle(_eventPile);
    }
    return _eventPile.removeAt(0);
  }

  CardDef? drawGoodLuck(GameState state, int playerIdx) {
    if (_goodLuckPile.isEmpty) {
      _goodLuckPile = List.of(library.goodLuck);
      engine.rng.shuffle(_goodLuckPile);
    }
    if (state.goodLuckDrawsThisLap[playerIdx] >= engine.balance.maxGoodLuckPerLap) {
      return null;
    }
    state.goodLuckDrawsThisLap[playerIdx] =
        state.goodLuckDrawsThisLap[playerIdx] + 1;
    return _goodLuckPile.removeAt(0);
  }

  CardDef drawBadLuck() {
    if (_badLuckPile.isEmpty) {
      _badLuckPile = List.of(library.badLuck);
      engine.rng.shuffle(_badLuckPile);
    }
    return _badLuckPile.removeAt(0);
  }

  CardDef drawLuck(GameState state, int playerIdx) {
    if (engine.rng.chance(0.5)) {
      return drawGoodLuck(state, playerIdx) ?? drawBadLuck();
    }
    return drawBadLuck();
  }

  void resetLapCounters(GameState state) {
    for (var i = 0; i < state.goodLuckDrawsThisLap.length; i++) {
      state.goodLuckDrawsThisLap[i] = 0;
    }
  }
}

class Movement {
  final GameEngine engine;
  final List<Tile> board;
  Movement(this.engine, this.board);

  List<GameEvent> rollAndMove(GameState state, int playerIdx) {
    final p = state.players[playerIdx];
    final ev = <GameEvent>[];

    final dice = engine.rng.rollDice();
    state.lastDiceRoll = dice;
    final from = p.position;
    final to = (from + dice.total).clamp(0, board.length - 1);
    p.position = to;
    ev.add(Moved(playerIdx, from, to));

    // Fuel subsidy extra cost (event E06): +Rp 0.2M per roll for affected laps.
    if (p.fuelSubsidyLapsLeft > 0 && p.fuelSubsidyExtraPerRoll > 0) {
      p.cash -= p.fuelSubsidyExtraPerRoll;
      ev.add(CashDelta(
          playerIdx, -p.fuelSubsidyExtraPerRoll, 'Fuel subsidy extra'));
    }

    // Lap completion: any time we wrap around. With our clamped movement
    // (max = board.lastIndex), wrap is unlikely — but keep parity with
    // the Kotlin impl which also tracks lapsCompleted on wrap.
    if (to < from) {
      p.lapsCompleted += 1;
      ev.add(LapCompleted(playerIdx, p.lapsCompleted));
    }

    return ev;
  }
}
