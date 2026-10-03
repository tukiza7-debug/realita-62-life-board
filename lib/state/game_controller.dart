/// Game controller — ChangeNotifier that wraps a [GameOrchestrator] and
/// exposes simple methods the UI can call. Hides engine wiring.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:realita_engine/realita_engine.dart';

class GameController extends ChangeNotifier {
  GameController._(this._orch) : super();
  late GameOrchestrator _orch;
  GameOrchestrator get orchestrator => _orch;

  /// Load a saved game from a JSON string. Returns null if load fails
  /// (corrupted save — caller should prompt the user to start fresh).
  static Future<GameController?> loadSaved(String json) async {
    try {
      final lib = await _loadCardLibrary();
      final orch = GameOrchestrator.deserialize(json, lib, BalanceConfig.defaultConfig);
      return GameController._(orch);
    } catch (_) {
      return null;
    }
  }

  /// Create a fresh state JSON for a new game. Used by NewGameScreen.
  static String createInitialStateJson({
    required int seed,
    required List<PlayerSeed> players,
  }) {
    final ps = players
        .map((p) => Player(id: p.id, name: p.name, isAI: p.isAI))
        .toList();
    final state = GameState(seed: seed, players: ps);
    final orchJson = _stateToJson(state);
    return jsonEncode(orchJson);
  }

  static Map<String, dynamic> _stateToJson(GameState state) => {
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

  /// Load the card library from `assets/data/cards.json`.
  static Future<CardLibrary> _loadCardLibrary() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/cards.json');
    final lib = CardLibrary.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    // Defensive: verify card counts.
    assert(lib.events.length == 30,
        'Expected 30 event cards, got ${lib.events.length}');
    assert(lib.goodLuck.length == 20,
        'Expected 20 good luck cards, got ${lib.goodLuck.length}');
    assert(lib.badLuck.length == 20,
        'Expected 20 bad luck cards, got ${lib.badLuck.length}');
    return lib;
  }

  // ----------------------- Turn state machine ----------------------------

  bool _busy = false;
  bool get busy => _busy;

  void setEducation(int playerIdx, EducationPath path) {
    _orch.setEducation(playerIdx, path);
    notifyListeners();
  }

  void assignCareer(int playerIdx, Career career) {
    _orch.assignCareer(playerIdx, career);
    if (_orch.state.players.every((p) => p.career != null)) {
      _orch.startGame();
    }
    notifyListeners();
  }

  /// Take a turn for the current player. Returns the events raised.
  /// Spamming taps cannot double-act: while busy is true, the call is a
  /// no-op.
  List<GameEvent> takeTurn() {
    if (_busy) return const [];
    _busy = true;
    try {
      final result = _orch.takeTurn();
      notifyListeners();
      return result.events;
    } finally {
      _busy = false;
    }
  }

  void applyChoice(String cardId, String choice) {
    final card = _orch.cardLibrary.findById(cardId);
    if (card == null) return;
    _orch.applyChoiceAndContinue(card, choice);
    notifyListeners();
  }

  void applyMarriage(bool lavish) {
    _orch.applyMarriage(lavish);
    notifyListeners();
  }

  void applyAssetPurchase(String assetId) {
    _orch.applyAssetPurchase(assetId);
    notifyListeners();
  }

  void applyMaharPartai(bool enter, {bool corrupt = false}) {
    _orch.applyMaharPartai(enter, corrupt: corrupt);
    notifyListeners();
  }

  void applyRetirement(RetirementChoice choice) {
    _orch.applyRetirement(choice);
    notifyListeners();
  }

  /// Serialize current state back to JSON for autosave.
  String serialize() => _orch.serialize();
}

/// Lightweight DTO used by NewGameScreen.
class PlayerSeed {
  final int id;
  final String name;
  final bool isAI;
  const PlayerSeed({
    required this.id,
    required this.name,
    required this.isAI,
  });
}
