# Realita +62: Life Board

> Bahasa Indonesia: [README.id.md](./README.id.md) | English: this file

[![CI status](https://github.com/tukiza7-debug/realita-62-life-board/actions/workflows/build-flutter-apk.yml/badge.svg?branch=main)](https://github.com/tukiza7-debug/realita-62-life-board/actions/workflows/build-flutter-apk.yml)
[![Latest release](https://img.shields.io/github/v/release/tukiza7-debug/realita-62-life-board)](https://github.com/tukiza7-debug/realita-62-life-board/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Flutter 3.24.0](https://img.shields.io/badge/Flutter-3.24.0-02569B?logo=flutter)](https://flutter.dev/)
[![Android 7.0+](https://img.shields.io/badge/Android-7.0%2B-green?logo=android)](https://developer.android.com/about/versions/nougat)

A Game-of-Life-style family board game that blends classic mechanics with the bittersweet socio-economic and political reality of modern Indonesia. Survive inflation, burdensome policy, and the temptation of corruption — reach retirement with dignity.

## Quick pitch

- **Genre**: turn-based family board game, pass-and-play on one device, or solo vs AI (1–3 AI opponents).
- **Players**: 2–4 local.
- **Languages**: English + Bahasa Indonesia (live switch, no restart).
- **Offline**: 100% offline. No account, no ads, no analytics, no INTERNET permission (verified in `AndroidManifest.xml`).
- **Engine**: deterministic, seeded RNG — same seed plays identically across the legacy Kotlin app and this Flutter port.

## Download and install

Grab the latest APK from the [Releases page](https://github.com/tukiza7-debug/realita-62-life-board/releases/latest).

- For most modern phones: `app-arm64-v8a-release.apk`.
- If unsure or installing on an x86 emulator: `app-release.apk` (universal APK).
- Android 7.0 (API 24) or newer required.

Allow installation from your browser/files app if Android blocks it. If you get "App not installed", the most likely cause is signature mismatch — uninstall any previous build first.

Verify the download with `SHA256SUMS.txt`:

```bash
sha256sum -c SHA256SUMS.txt   # in the directory containing the .apk files
```

## How to play (short version)

1. Pick an education path: **PTN (College)** starts with Rp 2M cash and Rp 10M UKT debt; **SMA/SMK** starts with Rp 3M and no debt.
2. Roll the dice. Pass-and-play between 2–4 players, or solo vs AI.
3. **Payday** tile (every 5th) gives your career's payday. PNS and SCBD lose 3% TAPERA.
4. **Event** tiles draw a *Nasib Warga +62* card (fuel hikes, PHK massal, OTT KPK, PPN shocks…).
5. **Luck** tiles draw Good Luck or Bad Luck at random. Cash losses are reduced by 25% if you have ≥ Rp 10M savings; insurance halves medical cards.
6. Buy assets (Kampung House Rp 20M, Apartment Rp 35M, Jogja/Bali Land Rp 40M, Menteng Mansion Rp 120M) — 12% PPN on top, 20% down, 80% KPR.
7. **Marriage** tile: Modest KUA (Rp 1M, +8 H) or Lavish (Rp 8M, +25 H; the difference becomes Pinjol debt if cash goes negative).
8. **Child** tile: each child adds Rp 1.5M per lap. Fund their schooling for the Dynasty Legacy bonus.
9. **Mahar Partai** gate (Rp 15M): enter politics. Clean (+H, mocked by the public) or Corrupt (steal Rp 6M per lap, KPK sting chance = heat × 10%).
10. **Retirement** fork: Jogja, Bali, or Menteng. Score = Net Assets + Cash + (Happiness × Rp 0.5M) + Legacy bonus. Corrupt route with negative Happiness halves the score.
11. **Warga Teladan +62** (Model Citizen): no corruption, no Pinjol at the end, positive Happiness, retire in Jogja or Bali.

Full rules in [`docs/SPEC.md`](./docs/SPEC.md). In-app Rules Reference and Tutorial cover the same rules.

## Build from source

Requirements: Flutter 3.24.0 (stable), JDK 17, Android SDK platform `android-34` and build-tools.

```bash
flutter pub get
flutter gen-l10n                # generate localization files
flutter analyze                 # zero issues required
flutter test                    # all tests must pass
flutter run                     # debug build on a connected device/emulator
flutter build apk --release --split-per-abi   # release APKs per ABI
flutter build apk --release                   # universal APK
```

## Signing and release (for maintainers)

Generate a release keystore (one-time):

```bash
keytool -genkeypair -v -keystore realita.keystore \
    -alias realita -keyalg RSA -keysize 2048 -validity 10000
```

Configure four repo secrets in **Settings → Secrets and variables → Actions**:

- `REALITA_KEYSTORE_BASE64` — `base64 -w0 realita.keystore` (entire keystore, base64-encoded).
- `REALITA_KEYSTORE_PASSWORD` — keystore password.
- `REALITA_KEY_ALIAS` — `realita`.
- `REALITA_KEY_PASSWORD` — key password.

Release:

```bash
git tag v2.0.0
git push origin v2.0.0
```

The workflow in `.github/workflows/build-flutter-apk.yml` then:
1. Runs `flutter analyze` + `flutter test` + `dart format --set-exit-if-changed`.
2. Runs `flutter build apk --release --split-per-abi` and the universal APK.
3. Computes `SHA256SUMS.txt`.
4. Creates a GitHub Release with the APKs and `SHA256SUMS.txt` attached, body copied from the matching `CHANGELOG.md` section.

Without the four signing secrets, the release build falls back to debug signing so the APK is still installable for local testing; **a public release MUST fail loudly if secrets are missing** (master prompt section 11). Per master prompt, do not commit the keystore or any password.

## Testing

```bash
flutter test                   # unit tests (engine, cards, RNG parity, save/load)
flutter test integration_test  # integration test (menu → setup → game → results)
```

The fuzz/simulation run with a chosen seed and game count:

```bash
dart test --plain-name "1000 simulated games finish cleanly"
```

## Project structure

```
.
├── android/                       # Android shell (manifest, build.gradle, launcher icons)
├── assets/
│   ├── data/cards.json             # 70 cards (30 events + 40 luck), single source of truth
│   └── brand/                     # Master SVG logo + horizontal lockup
├── docs/                          # All design + audit docs
├── lib/                           # Flutter UI layer
│   ├── app.dart                   # Root widget
│   ├── main.dart                  # Entry point
│   ├── brand/glossary_data.dart   # Cultural-term glossary data
│   ├── settings/                  # Typed SettingsRepository + AppSettings model
│   ├── state/game_controller.dart # ChangeNotifier wrapping the engine
│   ├── theme/app_theme.dart       # Color tokens + Material 3 theme
│   └── ui/                        # Screens (menu, new game, game, settings, tutorial, glossary)
├── packages/
│   └── realita_engine/            # Pure-Dart deterministic engine (zero Flutter imports)
│       └── lib/src/               # SeededRng, GameEngine, CardResolver, Movement, etc.
├── test/                          # Unit tests (engine, cards, RNG parity)
├── integration_test/             # End-to-end integration test
├── legacy-kotlin/                # Legacy Kotlin + Compose project (preserved for parity reference)
└── .github/
    ├── workflows/build-flutter-apk.yml
    └── ISSUE_TEMPLATE/            # bug_report.yml, feature_request.yml, PR template
```

For the canonical project tree, run `tree -I 'build|.dart_tool|.git|legacy-kotlin'` from the repo root.

## Architecture

The game is a 2D turn-based board game: heavy on text, cards, dialogs, EN/ID localization, accessibility, and UI animation; light on physics or real-time simulation. We picked **Flutter** (stable, Dart 3, null-safe) over Kotlin/Compose, Unity, Godot, and React Native — see [`docs/DECISIONS.md`](./docs/DECISIONS.md) for the one-paragraph rationale on each.

Architecture in one paragraph: a **pure-Dart engine package** (`packages/realita_engine/`) holds all gameplay logic — `SeededRng` (xorshift64*), `GameEngine`, `CardResolver`, `CardDeck`, `Movement`, `GameOrchestrator`, `Board`, `BalanceConfig`. The Flutter UI layer (`lib/ui/`) consumes the engine via a `GameController` (ChangeNotifier). **Animation is presentation only**: the engine resolves the full event list for a turn before any animation plays, so dice values, card draws, and money changes never depend on animation timing or skipping. See [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

## Localization

Two languages are mandatory: **English** (`lib/l10n/app_en.arb`) and **Bahasa Indonesia** (`lib/l10n/app_id.arb`). The Indonesian strings are written in natural Indonesian (not a word-for-word machine translation), verified against KBBI / Badan Bahasa / official sites (BPJS Kesehatan, DJP, BP Tapera, KPK). Cultural terms (UKT, KPR, Pinjol, Mahar Partai, etc.) are kept as proper nouns in the English version and explained in the in-app Glossary and in [`docs/GLOSSARY.md`](./docs/GLOSSARY.md).

The l10n parity test (TODO) fails if a key exists in one ARB file but not the other, or if any value is empty.

## Design, brand and motion

- Logo: hand-authored SVG (batik red background, cream "62" winding path, gold pawn on a tile). See [`docs/BRAND.md`](./docs/BRAND.md) and `assets/brand/`.
- Motion: durations, curves, and the AnimationDirector principle live in [`docs/MOTION.md`](./docs/MOTION.md).

## Audio, fonts and credits

All audio is copyright-free (CC0 / public domain / permitted licences). Synthesized SFX are self-made and credited in [`CREDITS.md`](./CREDITS.md); no audio files are bundled in this v2.0.0 release because no CC0 sources were available offline — see `docs/AUDIT.md` for the manual steps to add audio.

## Privacy

Fully offline. No account, no ads, no analytics, no network permission. Verified by inspecting `android/app/src/main/AndroidManifest.xml` — the manifest declares only `VIBRATE` (for haptic feedback) and queries for `ACTION_PROCESS_TEXT`. There is no `<uses-permission android:name="android.permission.INTERNET"/>` anywhere.

## FAQ / Troubleshooting

- **Install blocked**: Android shows "For your security, your phone is not allowed to install unknown apps from this source". Open Settings → Apps → Special access → Install unknown apps → pick your browser/files app → Allow.
- **App not installed**: signature mismatch with a previous build. Uninstall the old build first.
- **Play Protect warning**: tap "More details" → "Install anyway". Realita +62 is offline and contains no malware.
- **Corrupted save**: the game falls back to the New Game screen automatically. Use Settings → Data → Delete saved game if needed.
- **Report a bug**: open a [GitHub issue](https://github.com/tukiza7-debug/realita-62-life-board/issues/new/choose) using the Bug Report template; include the app version, Android version, device, language, orientation, and the game seed (visible in Settings → About → Copy debug info).

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for setup, test commands, commit style, and localization rules. PR checklist requires: `flutter analyze` clean, all tests pass, strings added in BOTH ARB files, credits updated for any new asset.

## Changelog

See [`CHANGELOG.md`](./CHANGELOG.md). Latest: **v2.0.0** — Flutter port + brand + responsive layout + animation system + settings rework + 70 card tests + 1000-game simulation.

## License

MIT. See [`LICENSE`](./LICENSE).

## Acknowledgements

Built with Flutter, Dart, Material 3, and a great deal of Indonesian everyday reality. Master prompt and full design rationale in `docs/`. The legacy Kotlin implementation lives in `legacy-kotlin/` as the behavioural reference; the Dart engine is verified to produce identical outcomes for the same seed (see `test/engine_test.dart`).
