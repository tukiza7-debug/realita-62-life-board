# Architecture

One-page overview of how the code is organized and how data flows.

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter UI layer (lib/ui/)                                  │
│  ┌───────────────┐  ┌────────────┐  ┌──────────────────┐    │
│  │ MainMenuScreen│  │ GameScreen │  │ SettingsScreen   │    │
│  └───────┬───────┘  └─────┬──────┘  └─────────┬────────┘    │
│          │                 │                    │             │
│          └────────┬────────┴────────────────────┘             │
│                   ▼                                           │
│      ┌────────────────────────────────┐                       │
│      │ GameController (ChangeNotifier) │                       │
│      │  - loadSaved(json)              │                       │
│      │  - takeTurn()                   │                       │
│      │  - applyChoice / Marriage / ... │                       │
│      │  - serialize() for autosave     │                       │
│      └────────────┬────────────────────┘                       │
│                   │                                           │
└───────────────────┼───────────────────────────────────────────┘
                    │ uses (no Flutter imports in engine)
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  Pure-Dart engine package (packages/realita_engine/)         │
│  ┌───────────────┐  ┌───────────────┐  ┌────────────────┐    │
│  │ SeededRng     │  │ GameEngine    │  │ CardResolver    │   │
│  │ (xorshift64*) │◄─┤ (payday,      │◄─┤ (resolveImmediate│  │
│  │               │  │  endOfLap,    │  │  + applyChoice) │  │
│  │               │  │  purchase,    │  │                 │   │
│  │               │  │  KPK sting,   │  │                 │   │
│  │               │  │  scoring,    │  │                 │   │
│  │               │  │  retire)      │  │                 │   │
│  └───────────────┘  └───────────────┘  └────────────────┘    │
│         ▲                                  ▲                  │
│         │                                  │                  │
│  ┌──────┴──────┐  ┌───────────┐  ┌─────────┴──────┐           │
│  │ Movement     │  │ CardDeck  │  │ GameOrchestrator│         │
│  │ (rollAndMove)│  │ (shuffle, │  │ (turn order,    │         │
│  │              │  │  draw)    │  │  pendingX, AI) │         │
│  └──────────────┘  └───────────┘  └────────────────┘         │
│                                                                │
│  Data:                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │ BalanceConfig│  │ BoardFactory │  │ CardLibrary (from  │   │
│  │ (tunables)   │  │ (60 tiles)   │  │ assets/data/cards) │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                │
│  State: GameState (seed, players[], turn, log[], gameOver)    │
│  + serialization to JSON (SharedPreferences 'saved_game').     │
└────────────────────────────────────────────────────────────────┘
```

## Key invariant

**Animation is presentation only.** `GameController.takeTurn()` runs the
engine synchronously and returns the full event list for that turn BEFORE
any animation plays. The UI then renders those events (as a Game Log list
in v2.0.0; as a queued `AnimationDirector` in v2.1). Dice value, card
draw, and money change never depend on animation timing, frame rate, or
skipping.

## Determinism

All randomness goes through `SeededRng` (xorshift64*). The engine never
reads `Random()` or `DateTime.now()` for gameplay decisions. Same seed →
same game. This is verified by `test/engine_test.dart`'s
`same seed produces same dice sequence` and
`string seed is reproducible` tests, and by the 70-card parity tests
against the legacy Kotlin implementation in `legacy-kotlin/`.

## Layering rules

- `lib/ui/` imports `lib/state/game_controller.dart` and `lib/settings/settings_repository.dart`.
- `lib/state/game_controller.dart` imports `packages/realita_engine/realita_engine.dart`.
- `packages/realita_engine/` imports nothing from `lib/` or from `package:flutter/`.
- `lib/l10n/` is generated from `app_en.arb` / `app_id.arb` via `flutter gen-l10n`.
- `lib/brand/glossary_data.dart` is plain Dart data; the Glossary screen consumes it.

## Save schema versioning

`GameState._stateToJson` writes `schemaVersion: 1`. On load,
`SettingsRepository.load()` checks the saved schema version and can run
migrations. v2.0.0 has only schema v1; a v2 migration hook is documented
in `lib/settings/settings_repository.dart`.
