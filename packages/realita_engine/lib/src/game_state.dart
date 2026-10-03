/// Game state container + serialization. Mirrors the Kotlin `GameState`
/// data class so a save written by the Kotlin app could be loaded by the
/// Flutter app (subject to schema versioning — see docs/ARCHITECTURE.md).
library;

import 'dart:convert';

import 'package:realita_engine/src/models.dart';
import 'package:realita_engine/src/seeded_rng.dart';
import 'package:realita_engine/src/game_event.dart';

class GameState {
  final int seed;
  final List<Player> players;
  int turn;
  int currentPlayerIdx;
  final List<GameEvent> log;
  AssetCatalogue assetCatalogue;
  final List<String> drawnEvents;
  final List<String> drawnLuck;
  final List<int> goodLuckDrawsThisLap;
  bool gameOver;
  DiceRoll? lastDiceRoll;

  GameState({
    required this.seed,
    required this.players,
    this.turn = 0,
    this.currentPlayerIdx = 0,
    List<GameEvent>? log,
    AssetCatalogue? assetCatalogue,
    List<String>? drawnEvents,
    List<String>? drawnLuck,
    List<int>? goodLuckDrawsThisLap,
    this.gameOver = false,
    this.lastDiceRoll,
  })  : log = log ?? [],
        assetCatalogue = assetCatalogue ?? AssetCatalogue.defaultCatalogue,
        drawnEvents = drawnEvents ?? [],
        drawnLuck = drawnLuck ?? [],
        goodLuckDrawsThisLap =
            goodLuckDrawsThisLap ?? List.filled(players.length, 0);
}
