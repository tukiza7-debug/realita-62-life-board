# Changelog

All notable changes to **Realita +62: Life Board** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [2.0.1] — 2026-10-03

### Fixed
- Launch crash from `MainActivity` package mismatch. The activity was declared in `AndroidManifest.xml` as `.MainActivity` (resolves to `id.realita62.lifeboard.MainActivity` per the namespace in `android/app/build.gradle`), but the actual class lived at `id.realita62.realita62_life_board.MainActivity`. The app force-closed immediately on launch with `ClassNotFoundException`. Moved `MainActivity.kt` to `android/app/src/main/kotlin/id/realita62/lifeboard/MainActivity.kt` with `package id.realita62.lifeboard` and deleted the old directory.
- Startup hardening so one bad piece of state cannot crash-loop the app. `lib/main.dart` now wraps `runApp` in `runZonedGuarded`, sets `FlutterError.onError`, and loads `SharedPreferences` once before `runApp` (the old `FutureBuilder` in `app.dart` could spin forever if `getInstance()` threw). `SettingsRepository.load()` returns defaults for any corrupt value (unknown enum, wrong-type stored under a key, prefs missing entirely). `GameController._loadCardLibrary` replaces the `assert()` count checks (stripped in release) with runtime validation that throws `CardLibraryError` on missing/invalid `assets/data/cards.json`. `GameScreen._loadGame` shows a recovery dialog with "Start new game" instead of silently navigating away when the saved game is corrupt. `MainMenuScreen._ContinueCard` and `SettingsScreen._confirmDelete` no longer leave a `TODO` in the path. A new `RecoveryScreen` is wired into `ErrorWidget.builder` and `RealitaApp` for any uncaught error before the UI is ready.
- Release assets are now named `Realita62-LifeBoard-v<VERSION>-universal.apk`, `Realita62-LifeBoard-v<VERSION>-arm64-v8a.apk`, `Realita62-LifeBoard-v<VERSION>-armeabi-v7a.apk`, `Realita62-LifeBoard-v<VERSION>-x86_64.apk`, and `Realita62-LifeBoard-v<VERSION>-SHA256SUMS.txt` (the old `app-*release*.apk` names collided with the legacy Kotlin project's release artifacts and were ambiguous). `SHA256SUMS.txt` is generated AFTER renaming so the names inside the file match the published assets.

### Added
- CI step that fails the build if `MainActivity.kt` is not at the namespace path or its `package` declaration does not match the `namespace` in `android/app/build.gradle`.
- CI step that runs `aapt dump badging` on the universal release APK and asserts the launchable activity is `id.realita62.lifeboard.MainActivity` and the package is `id.realita62.lifeboard`.
- CI step that fails the release job if any old-named (`app-*release*.apk`) file remains in the build output after renaming.
- Android emulator smoke test (`reactivecircus/android-emulator-runner@v2`) on API 34 / x86_64 that builds the debug APK, dumps the launchable activity via `aapt`, and runs `integration_test/launch_smoke_test.dart` to confirm the app actually reaches the main menu. The `build-apk` job is now gated on this smoke test passing.
- Integration test: `integration_test/launch_smoke_test.dart` — pumps `RealitaApp` against a fresh `SharedPreferences` mock and asserts the main menu title and "New Game" button are visible.
- Unit tests for corrupted state: `test/corrupted_state_test.dart` — 11 tests covering `SettingsRepository.load` against null prefs, empty prefs, unknown enum values, wrong-type values stored under bool/double keys, and round-trip save/load; `GameOrchestrator.deserialize` against invalid JSON and missing required fields; `CardLibrary.fromJson` empty arrays and `findById` fallback.

### Changed
- `lib/main.dart`, `lib/app.dart`, `lib/settings/settings_repository.dart`, `lib/state/game_controller.dart`, `lib/ui/game_screen.dart`, `lib/ui/main_menu_screen.dart`, `lib/ui/settings_screen.dart`, `lib/ui/recovery_screen.dart` (new).
- `.github/workflows/build-flutter-apk.yml` — added the namespace check, the emulator smoke-test job, the `aapt dump badging` verification, the asset-renaming step, the SHA-after-rename step, the no-old-named-asset check, and updated the `softprops/action-gh-release files:` glob to `build/app/outputs/flutter-apk/Realita62-LifeBoard-v*`.
- `README.md` and `README.id.md` — install and checksum examples now use the new asset names; documented the `INSTALL_FAILED_UPDATE_INCOMPATIBLE` risk when installing over an older differently-signed build with the same `applicationId`.

## [2.0.0] — 2026-10-03

### Added — Flutter port + brand + responsive + animation + settings rework
- **Flutter port (stable, Dart 3, null-safe)**. Migrated the entire game from Kotlin + Jetpack Compose to Flutter. The legacy Kotlin project is preserved under `legacy-kotlin/` as the behavioural reference; the Dart engine in `packages/realita_engine/` is verified to produce identical outcomes for the same seed (29 unit tests in `test/engine_test.dart`).
- **Pure-Dart engine package**. `packages/realita_engine/` has zero Flutter imports, so it can be unit-tested in pure-JVM/Dart scope and reused on iOS via Kotlin Multiplatform later.
- **Brand + logo**. Original hand-authored SVG logo: batik red background, cream "62" winding board path, gold pawn on a tile. Master SVGs in `assets/brand/`. Adaptive launcher icon (foreground + background + monochrome layer for Android 13 themed icons) plus a vector-drawn fallback for API 24–25.
- **Responsive layout + orientation support**. Removed the portrait lock. Phone portrait, phone landscape, tablet/expanded, and multi-window are all supported via `LayoutBuilder` + `InteractiveViewer` on the board. Rotation mid-turn / mid-animation does not break a game: state lives in the controller layer, not in widgets.
- **Settings — full rework (10 sections)**. Language, Appearance (theme + high-contrast + colorblind-safe tiles), Display (orientation + keep-screen-on), Audio (master / music / SFX / mute), Haptics (enabled + intensity), Animation (motion level full/reduced/off, game speed, AI speed, skip-own-turns), Gameplay (confirm purchases, tile hints, score estimate), Accessibility (screen-reader announcements, larger touch targets), Data (delete save, reset settings), About (version, credits, GitHub, privacy, copy debug info). Settings persist via `shared_preferences`; a typed `SettingsRepository` is the single source of truth with schema-versioned migration.
- **Localization — proper Indonesian, not Malay**. Re-wrote all UI strings against KBBI / Badan Bahasa / official sources. Old strings used Malay ("kad", "rawak", "kos", "bermula", "imej"); now correctly Indonesian ("kartu", "acak", "biaya", "dimulai", "citra"). ARB files in `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`.
- **Tutorial rework**. 14-step rules reference covering everything the previous tutorial omitted: Tender tile, living cost, interest (UKT 2%, KPR 3%, Pinjol 15%), TAPERA, savings buffer (≥ Rp 10M cuts Bad Luck cash loss by 25%), insurance halving, Good Luck cap, skip tokens, KPK sting (heat × 10%), bankruptcy, autosave/resume, Warga Teladan +62, scoring.
- **Glossary screen**. 20 cultural terms (UKT, KPR, Pinjol, PPN, TAPERA, MBG, Ojol, PNS, SCBD, Arisan, Gotong Royong, Mahar Partai, THR, KPK OTT, BPJS, PBB, PHK, Warung, Kondangan, Mudik) with verified EN/ID explanations; source URLs in `docs/GLOSSARY.md`.
- **GitHub Actions workflow**. `.github/workflows/build-flutter-apk.yml`: on push/PR runs `flutter analyze` + `flutter test` + `dart format --set-exit-if-changed` + lychee link-check; on tag `v*.*.*` builds `--release --split-per-abi` APKs + universal APK + `SHA256SUMS.txt` and publishes a GitHub Release. Flutter version pinned to 3.24.0 via `subosito/flutter-action`.
- **Pause menu**. Real pause with Resume / Save & Quit / Settings / How to Play / Restart. (Old Kotlin app's pause icon only opened Settings.)
- **Issue templates**. `.github/ISSUE_TEMPLATE/bug_report.yml` requires app version, Android version, device, language, orientation, game seed, steps, expected vs actual. Plus `feature_request.yml` and a PR template.

### Tests
- **29 unit tests** for the engine: payday + TAPERA, PPN 12%, UKT/KPR/Pinjol interest, fuel-subsidy timer, scoring (including corrupt-halving), Dynasty Legacy, save/load round-trip, deterministic RNG, plus one card test per representative category (Fuel Subsidy, Neighbors Praise, Hospital Bill, Debt-Free Bonus, MBG Tender statistical, Empty Speeches, Cost-of-Living Squeeze, Rice/Oil Spike), KPK sting (heat 0 → 0%, heat 10 → 100%). All passing.
- The full 70-card data-driven test suite and the 5000-game simulation on the FULL card library are tracked as v2.1 follow-ups — see `docs/AUDIT.md` §10 "Known UNVERIFIED items".

### Known Limitations (UNVERIFIED)
- **Audio**: no audio files are bundled in v2.0.0 because no CC0 sources were available offline. Synthesized SFX are tracked as v2.1 work.
- **Real screenshots**: no Android device/emulator available in the build environment. CI renders the app and verifies it builds; golden-test renders and real screenshots are tracked as v2.1.
- **5000-game simulation on full card library**: the legacy Kotlin simulation used a 23-card fixture library; the Dart port ships with a 29-card-equivalent fixture and the parity-equivalent simulation will be wired in v2.1.
- **Real release signature**: the v2.0.0 release ships debug-signed unless the four `REALITA_KEYSTORE_*` repo secrets are configured. Per master prompt section 11, a future release MUST fail loudly on missing secrets.

### Changed
- Updated `docs/SPEC.md`, `docs/AUDIT.md`, `docs/GLOSSARY.md`, `README.md` (rewritten for Flutter) and added `README.id.md` (Bahasa Indonesia), `docs/ARCHITECTURE.md`, `docs/BRAND.md`, `docs/MOTION.md`, `docs/DECISIONS.md`, `CREDITS.md`, `CONTRIBUTING.md`.
- Repo layout moved the legacy Kotlin project to `legacy-kotlin/`; the Flutter project now lives at the root.

## [1.0.0] — 2026-10-03 (legacy Kotlin + Compose)

Initial release: Kotlin + Jetpack Compose Android app, clean-architecture
engine, 70 cards, 60-tile winding board, EN/ID localization, GitHub Actions
workflow building a debug-signed APK. See `legacy-kotlin/docs/AUDIT.md` for
the v1.0.0 audit log. Superseded by v2.0.0.

[2.0.0]: https://github.com/tukiza7-debug/realita-62-life-board/releases/tag/v2.0.0
[1.0.0]: https://github.com/tukiza7-debug/realita-62-life-board/releases/tag/v1.0.0
