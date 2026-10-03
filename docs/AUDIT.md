# AUDIT — Realita +62 Life Board v2.0.0

Every line below points to a command, a test name, or a CI step that
was actually run. Anything not run is marked **UNVERIFIED**.

## 1. Static analysis

### Command (run locally before push)
```bash
flutter analyze
```

### Result
```
0 errors.
13 warnings (mostly unused imports + unused local variables — non-blocking).
68 infos (prefer_const_constructors, use_super_parameters — non-blocking).
```

The CI workflow runs `flutter analyze` and **fails the build on any error**.
Warnings are not treated as errors in v2.0.0; the v2.1 task is to either fix
all warnings or upgrade `analysis_options.yaml` to `treat-warnings-as-errors: true`.

### Command
```bash
dart format --set-exit-if-changed .
```
**UNVERIFIED in this commit** — CI runs it but local run was not captured.

## 2. Unit tests

### Command (run locally before push)
```bash
flutter test
```

### Result
```
00:06 +29: All tests passed!
All 29 tests passed.
```

Tests live in `test/engine_test.dart`. Coverage at v2.0.0:

- **Payday + TAPERA**
  - `payday pays gross for Ojol Driver with no TAPERA`
  - `payday applies TAPERA 3% for PNS`
  - `payday applies TAPERA 3% for SCBD`
  - `payday skipped when player has skipsNextPayday flag`
- **Interest**
  - `UKT interest is 2% per lap`
  - `KPR interest is 3% per lap on remaining principal`
  - `Pinjol interest is 15% per lap`
- **PPN 12%**
  - `asset purchase applies PPN 12% and 20% down payment`
  - `asset purchase fails when cash is insufficient`
- **Fuel subsidy (event E06)**
  - `fuel subsidy timer ticks down each lap`
- **Scoring**
  - `clean player score = netAssets + cash + (H * 0.5M)`
  - `corrupt player with negative H has score halved`
  - `corrupt player with positive H keeps full score`
- **Warga Teladan +62**
  - `Warga Teladan: no corruption, no Pinjol, positive H, Jogja/Bali`
- **Dynasty Legacy**
  - `funded child adds 3M, unfunded adds 0.5M`
  - `nepotism perk halves funded legacy bonus`
- **Save / Load**
  - `game state serializes and round-trips back`
- **Deterministic RNG**
  - `same seed produces same dice sequence`
  - `string seed is reproducible`
- **Card tests (one per representative category)**
  - `EVENT_FUEL_SUBSIDY_REMOVED applies to Ojol and Daily Worker only`
  - `GL_NEIGHBORS_PRAISE gives 15H to clean route, 10H otherwise`
  - `BL_HOSPITAL_BILL is halved when player is insured`
  - `EVENT_DEBT_FREE_BONUS gives 4H and 1M cash when no debt`
  - `EVENT_MBG_TENDER skim has ~35% investigation chance` (statistical)
  - `EVENT_EMPTY_SPEECHES hits all players with -10H`
  - `EVENT_COST_OF_LIVING_SQUEEZE applies one extra living cost`
  - `BL_RICE_OIL_SPIKE applies to all players`
- **KPK Sting**
  - `KPK sting chance equals heat * 10%`
  - `KPK sting catches corrupt players proportional to heat`

### Per-card test coverage (master prompt section 10.2 requires a test for each of the 70 cards)

8 of 70 cards have dedicated tests (above). The other 62 cards share the same
code path (`CardResolver.resolveImmediate` / `applyChoice`), so structural
coverage is in place. **A data-driven test for every one of the 70 cards is
tracked as v2.1** — see §10 below.

## 3. Simulation (master prompt section 10.3 — 5000 games on the FULL card library)

**UNVERIFIED in this v2.0.0 commit** — the legacy Kotlin simulation used a
23-card fixture; the Dart port ships with the engine unit tests above but
does NOT yet wire a 5000-game simulation on the full card library.

v2.1 task: add `test/simulation_test.dart` that runs 5000 games on the full
`cards.json` (all 70 cards) and asserts:
- All games finish in ≤ 200 turns.
- No NaN/Infinite scores.
- No single route (NONE / CLEAN / CORRUPT) wins more than ~40%.

## 4. Widget + golden tests

**UNVERIFIED in this v2.0.0 commit** — the responsive layout is implemented
via `LayoutBuilder` + `InteractiveViewer`, but golden-test renders at the
master prompt section 5 sizes (360×640, 360×800, 412×915, 800×360, 600×960,
1280×800, foldable inner 673×841) in EN + ID, light + dark, are NOT yet
captured. v2.1 task.

## 5. Integration test

**UNVERIFIED in this v2.0.0 commit** — `integration_test/` directory exists
but the test file (menu → setup → full game → results, including a rotation
mid-turn and a settings change mid-game) is NOT yet written. v2.1 task.

## 6. Manual adversarial checklist

**UNVERIFIED** — no device available. Items to verify on v2.1:
- [ ] Rapid taps on Roll Dice (cannot double-act — `GameController.busy` guards).
- [ ] Back button mid-turn (Flutter's default `WillPopScope` returns to menu without losing state).
- [ ] App killed mid-turn (autosave after every turn — `SharedPreferences.setString('saved_game', ...)`)
- [ ] Rotation during animation (state lives in controller, not widgets).
- [ ] Multi-window resize (LayoutBuilder reflows).
- [ ] Language switch mid-game (live switch via `MaterialApp.locale`).
- [ ] Dark mode (Material 3 `darkTheme`).
- [ ] 200% font (no overflow guards yet — UNVERIFIED).
- [ ] TalkBack labels (semantics on every button — UNVERIFIED).
- [ ] Low-RAM device (UNVERIFIED).
- [ ] Airplane mode (no network permission — should be fine).
- [ ] System "remove animations" ON (Settings → Motion level — should respect it; UNVERIFIED wiring).

## 7. Performance profile

**UNVERIFIED in this v2.0.0 commit** — no `flutter run --profile` timeline
captured. v2.1 task: jank report, APK size, cold start, memory across a
full game.

## 8. Dependency audit

- **All dependencies**: flutter, flutter_localizations, cupertino_icons,
  shared_preferences, provider, collection, realita_engine (path).
- **No analytics, no Firebase, no INTERNET-using packages**.
- **Versions pinned** in `pubspec.yaml`.
- **Licences**: all MIT or BSD-style; compatible with MIT app licence.

## 9. Privacy verification

`android/app/src/main/AndroidManifest.xml` declares only:
```xml
<uses-permission android:name="android.permission.VIBRATE" />
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

No `<uses-permission android:name="android.permission.INTERNET"/>` anywhere
in the repo (verified via `grep -r INTERNET android/` — no matches).

## 10. Bugs found and fixed during v2.0.0

- **Bug**: legacy Kotlin `enterPoliticianPath` was called with 3 positional args
  in `applyMaharPartai`, but the Dart port made `corrupt` a named parameter.
  **Root cause**: signature mismatch between Kotlin and Dart port.
  **Fix**: changed the Dart call to `engine.enterPoliticianPath(state, idx, corrupt: corrupt)`.
  **Test**: `flutter analyze` reports 0 errors after the fix.
- **Bug**: `List<Tile>` does not have `lastIndex` (Kotlin's List does).
  **Root cause**: language difference.
  **Fix**: `board.length - 1` in `card_deck.dart`.
- **Bug**: `AppSettingsNotifier` defined in `app.dart` but `settings_screen.dart`
  did not import it.
  **Fix**: added `import '../app.dart';` to `settings_screen.dart`.
- **Bug**: `Clipboard` and `ClipboardData` not imported in settings_screen.dart.
  **Fix**: added `import 'package:flutter/services.dart';`.
- **Bug**: `PlayerSeed` was defined in both `new_game_screen.dart` and
  `game_controller.dart` — type mismatch.
  **Fix**: removed the duplicate in `new_game_screen.dart`; uses the one from
  `game_controller.dart` via import.
- **Bug**: the default `test/widget_test.dart` from `flutter create` referenced
  `MyApp` which didn't exist after the port.
  **Fix**: deleted `test/widget_test.dart`.

## 11. Known UNVERIFIED items (tracked for v2.1)

- Audio assets (no CC0 sources available offline).
- Real screenshots on a device/emulator.
- 5000-game simulation on the full card library.
- Per-card data-driven tests for the remaining 62 of 70 cards.
- Widget / golden tests at the master prompt section 5 matrix sizes.
- Integration test (menu → setup → game → results with rotation mid-turn).
- `flutter run --profile` jank report on a low-end device.
- 200% font overflow check.
- TalkBack semantics verification.
- Real release signature (debug-signed APK in v2.0.0; v2.1 must fail loudly
  on missing `REALITA_KEYSTORE_*` secrets).
- `aapt dump badging` verification of the released APK (no release yet at
  audit-write time).
- Lychee link-check report (CI runs it but no artifact captured yet).
