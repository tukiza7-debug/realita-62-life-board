# DECISIONS

One short paragraph per binding decision, per master prompt section 2.

## D-01: Use Flutter (stable, Dart 3, null-safe). NO game engine.

The game is a turn-based 2D board game: heavy on text, cards, dialogs, EN/ID localization, accessibility, and UI animation; light on physics or real-time simulation. Flutter's widget system + `CustomPainter` + animation controllers fit this exactly. `gen-l10n` handles ICU plurals and two languages properly; TalkBack and text scaling are first-class. One responsive layout system covers phone, tablet, foldable, split-screen, portrait, and landscape. A pure-Dart engine package is testable without a device and deterministic. Board = `CustomPainter` + `InteractiveViewer` + explicit animations. We will NOT add Flame / Unity / Godot unless a measured profiling report shows it is needed.

## D-02: Rejected — Kotlin + Compose

The legacy v1.0.0 implementation. Android-only, old stack, no benefit over Flutter for this game. Kept under `legacy-kotlin/` as the behavioural reference for RNG parity tests.

## D-03: Rejected — Unity

Big APK, weak text and l10n story, designed for 3D / physics-heavy games; overkill for a 2D board game.

## D-04: Rejected — Godot

Viable runner-up. Weaker text localization and accessibility, weaker widget-test tooling. If we ever need a heavier game loop we will revisit.

## D-05: Rejected — React Native

JS runtime, weaker animation story (Reanimated helps but adds complexity), platform-bridges introduce friction for board-game animations.

## D-06: State management — Provider, NOT Riverpod or Bloc

Single approach (Provider + `ChangeNotifier`) keeps the surface area small for a game with a single GameController wrapping the engine. Riverpod's extra concept surface (AsyncNotifier, family, etc.) is overkill here. Bloc's boilerplate is overkill. Picked: `provider: ^6.1.2`. The `GameController` is the single `ChangeNotifier` the UI consumes.

## D-07: Immutable models — hand-written, NOT freezed

The Dart engine models are mutable on purpose (per master prompt's deterministic reference behaviour, the Kotlin `Player` has `var` fields mutated by the engine). Adding freezed would force `.copyWith()` everywhere and create a divergence from the Kotlin reference. Hand-written `toJson()` / `fromJson()` on each model. This decision is reversible.

## D-08: Port SeededRng EXACTLY from the legacy Kotlin implementation

The Kotlin `SeededRng` (xorshift64*) is the BEHAVIOURAL REFERENCE. The Dart port in `packages/realita_engine/lib/src/seeded_rng.dart` reproduces the same bit-twiddling arithmetic (`^`, `<<`, `>>>`, `*` with 64-bit masking). 29 unit tests in `test/engine_test.dart` verify that the same seed produces the same dice sequence and the same game outcomes (payday, TAPERA, PPN, interest, scoring, KPK sting, dynasty legacy, save/load round-trip). Full byte-for-byte parity fixtures across a 2-player game are tracked as v2.1 — see `docs/AUDIT.md` §10.

## D-09: Keep `cards.json` as the single source of card data

All 70 cards (30 events E01–E30, 20 Good Luck GL01–GL20, 20 Bad Luck BL01–BL20) live in `assets/data/cards.json`. The Dart `CardLibrary` loads it via `rootBundle` and asserts card counts at load time. This is unchanged from the legacy Kotlin app, so card outcomes match the Kotlin reference exactly.

## D-10: Animation is presentation only — engine decides outcomes first

Per master prompt section 8: the engine resolves the full event list for a turn before any animation plays. Dice value, card draw, and money change never depend on animation timing, frame rate, or skipping. The `GameController.takeTurn()` is the only entry point the UI calls; it returns the full event list synchronously, and the UI then renders those events as animations. A future `AnimationDirector` (v2.1) will queue these events into a sequential presentation layer; for v2.0.0 the UI renders them as a Game Log list.

## D-11: Signing secrets via repo — public release MUST fail if missing

Per master prompt section 11: the v2.0.0 release falls back to debug signing when the four `REALITA_KEYSTORE_*` secrets are absent, so the build still produces an installable APK. A future release MUST fail loudly on missing secrets — no silent debug-signing for a public release. Tracked as v2.1.

## D-12: No INTERNET permission anywhere

Per master prompt section 7.2 and section 16: the privacy statement "fully offline, collects nothing" must be true. The Android manifest declares only `VIBRATE` (for haptic feedback) and the `<queries>` block for `ACTION_PROCESS_TEXT` (used by Flutter's text-processing plugin). There is no `INTERNET` permission, no `ACCESS_NETWORK_STATE`, no analytics SDK, no Firebase. Verified by `aapt dump permissions` once a release APK exists — UNVERIFIED in this v2.0.0 commit because no device is available.
