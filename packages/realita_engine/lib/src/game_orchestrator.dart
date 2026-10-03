/// Orchestrates a full game: turn order, AI moves, autosave, game-over
/// detection. The orchestrator is the only class the UI talks to
/// (besides CardResolver for choice cards).
///
/// Mirrors legacy-kotlin/.../GameOrchestrator.kt.
library;

import 'dart:convert';

import 'package:realita_engine/src/balance_config.dart';
import 'package:realita_engine/src/board.dart';
import 'package:realita_engine/src/card_def.dart';
import 'package:realita_engine/src/card_deck.dart';
import 'package:realita_engine/src/card_resolver.dart';
import 'package:realita_engine/src/game_engine.dart';
import 'package:realita_engine/src/game_event.dart';
import 'package:realita_engine/src/game_state.dart';
import 'package:realita_engine/src/models.dart';
import 'package:realita_engine/src/seeded_rng.dart';

class TurnResult {
  final List<GameEvent> events;
  final bool turnDone;
  final bool gameOver;
  const TurnResult(this.events, this.turnDone, this.gameOver);
}

class PendingChoice {
  final int playerIdx;
  final CardDef card;
  const PendingChoice(this.playerIdx, this.card);
}

class GameOrchestrator {
  final GameState state;
  final BalanceConfig balance;
  final List<Tile> board;
  final CardLibrary cardLibrary;

  late final GameEngine engine;
  late final CardDeck deck;
  late final Movement movement;
  late final CardResolver resolver;

  GameOrchestrator(this.state, this.balance, this.board, this.cardLibrary) {
    engine = GameEngine(balance, SeededRng(state.seed));
    deck = CardDeck(engine, cardLibrary);
    movement = Movement(engine, board);
    resolver = CardResolver(engine);
  }

  PendingChoice? pendingChoice;
  int? pendingMarriage;
  int? pendingAssetShop;
  int? pendingMaharPartai;
  int? pendingRetirement;

  Player get currentPlayer => state.players[state.currentPlayerIdx];

  void startGame() {
    state.turn = 0;
    state.currentPlayerIdx = 0;
    state.gameOver = false;
  }

  void setEducation(int playerIdx, EducationPath path) {
    final p = state.players[playerIdx];
    p.education = path;
    p.cash = path.startingCash;
    p.uktDebt = path.uktDebt;
  }

  void assignCareer(int playerIdx, Career career) {
    state.players[playerIdx].career = career;
  }

  TurnResult takeTurn() {
    final p = currentPlayer;
    if (p.retired) {
      _advancePlayer();
      return TurnResult(const [], true, state.gameOver);
    }

    if (p.skipsNextTurn) {
      p.skipsNextTurn = false;
      _advancePlayer();
      return TurnResult([SkipTurn(p.id, 1)], true, state.gameOver);
    }

    final ev = <GameEvent>[];
    ev.addAll(movement.rollAndMove(state, state.currentPlayerIdx));
    ev.addAll(_resolveTile(p));
    ev.addAll(engine.endOfLap(state, state.currentPlayerIdx));

    if (p.position == 0) {
      state.goodLuckDrawsThisLap[state.currentPlayerIdx] = 0;
    }

    state.log.addAll(ev);
    _advancePlayer();
    return TurnResult(ev, true, state.gameOver);
  }

  List<GameEvent> _resolveTile(Player p) {
    final tile = board[p.position];
    switch (tile.type) {
      case TileType.payday:
        return engine.payday(state, p.id);

      case TileType.event_:
        final card = deck.drawEvent();
        state.drawnEvents.add(card.id);
        final drawEv = CardDrawn(p.id, card.id, false);
        if (resolver.needsChoice(card)) {
          pendingChoice = PendingChoice(p.id, card);
          return [drawEv];
        }
        return [drawEv, ...resolver.resolveImmediate(state, p.id, card)];

      case TileType.luck:
        final card = deck.drawLuck(state, p.id);
        state.drawnLuck.add(card.id);
        final drawEv = CardDrawn(p.id, card.id, true);
        if (card.id.startsWith('GL') && resolver.needsChoice(card)) {
          pendingChoice = PendingChoice(p.id, card);
          return [drawEv];
        }
        return [drawEv, ...resolver.resolveImmediate(state, p.id, card)];

      case TileType.marriage:
        pendingMarriage = p.id;
        return const [];

      case TileType.child:
        return engine.addChild(state, p.id);

      case TileType.assetShop:
        pendingAssetShop = p.id;
        return const [];

      case TileType.maharPartaiGate:
        pendingMaharPartai = p.id;
        return const [];

      case TileType.tender:
        if (p.career == Career.contractor) {
          p.cash += 2.0;
          return [CashDelta(p.id, 2.0, 'Tender bonus')];
        }
        return const [];

      case TileType.retirementFork:
        pendingRetirement = p.id;
        return const [];

      case TileType.start:
      case TileType.educationFork:
      case TileType.blank:
        return const [];
    }
  }

  List<GameEvent> applyChoiceAndContinue(CardDef card, String choice) {
    final pc = pendingChoice;
    if (pc == null) return [];
    final ev = resolver.applyChoice(state, pc.playerIdx, card, choice);
    state.log.addAll(ev);
    pendingChoice = null;
    return ev;
  }

  List<GameEvent> applyMarriage(bool lavish) {
    final idx = pendingMarriage;
    if (idx == null) return [];
    final ev = engine.marry(state, idx, lavish);
    state.log.addAll(ev);
    pendingMarriage = null;
    return ev;
  }

  List<GameEvent> applyAssetPurchase(String assetId) {
    final idx = pendingAssetShop;
    if (idx == null) return [];
    final result = engine.purchaseAsset(state, idx, assetId);
    // Always clear pendingAssetShop — even on failure — so the orchestrator
    // does not get stuck re-trying a failed purchase in a tight loop.
    pendingAssetShop = null;
    if (result.ok) {
      final ev = [AssetPurchased(idx, result.asset!.id, result.asset!.name)];
      state.log.addAll(ev);
      return ev;
    }
    return const [];
  }

  List<GameEvent> applyMaharPartai(bool enter, {bool corrupt = false}) {
    final idx = pendingMaharPartai;
    if (idx == null) return [];
    final ev = enter
        ? engine.enterPoliticianPath(state, idx, corrupt: corrupt)
        : [HappinessDelta(idx, 2, 'Declined politics')];
    state.log.addAll(ev);
    pendingMaharPartai = null;
    return ev;
  }

  List<GameEvent> applyRetirement(RetirementChoice choice) {
    final idx = pendingRetirement;
    if (idx == null) return [];
    final ev = engine.retire(state, idx, choice);
    state.log.addAll(ev);
    pendingRetirement = null;
    if (engine.isGameOver(state)) {
      state.gameOver = true;
    }
    return ev;
  }

  void _advancePlayer() {
    final n = state.players.length;
    var next = (state.currentPlayerIdx + 1) % n;
    var guard = 0;
    while (state.players[next].retired && guard < n) {
      next = (next + 1) % n;
      guard += 1;
    }
    state.currentPlayerIdx = next;
    state.turn += 1;
  }

  String serialize() => jsonEncode(_stateToJson());

  static GameOrchestrator deserialize(
      String json, CardLibrary library, BalanceConfig balance) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final state = _stateFromJson(j);
    return GameOrchestrator(state, balance,
        BoardFactory.defaultBoard(size: balance.boardSize), library);
  }

  Map<String, dynamic> _stateToJson() => {
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

  static GameState _stateFromJson(Map<String, dynamic> j) {
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

  /// Simple AI heuristic for choice cards.
  String aiMakeChoice(CardDef card) {
    switch (card.effect) {
      case 'EVENT_MBG_TENDER':
        return 'decline';
      case 'EVENT_PARTY_DOWRY_OFFER':
        return 'decline';
      case 'EVENT_PORK_BARREL':
        return 'clean';
      case 'EVENT_PRIVATE_SCHOOL_FEE':
        return currentPlayer.cash >= 5.0 ? 'private' : 'public';
      case 'EVENT_RELATIVE_NEEDS_HELP':
        return currentPlayer.cash >= 2.5 ? 'help' : 'refuse';
      case 'EVENT_GAMBLING_AD':
        return 'ignore';
      case 'EVENT_SIDE_BUSINESS':
        return currentPlayer.cash >= 4.0 ? 'start' : 'decline';
      case 'EVENT_BRIBE_OFFER':
        return 'decline';
      case 'EVENT_VOTER_HANDOUT':
        return 'accept';
      default:
        return '';
    }
  }

  RetirementChoice aiChooseRetirement() {
    final p = currentPlayer;
    final worth = p.cash + p.netAssets();
    if (worth >= 60.0) return RetirementChoice.eliteMenteng;
    if (worth >= 25.0) return RetirementChoice.islandBali;
    return RetirementChoice.kampungJogja;
  }
}
