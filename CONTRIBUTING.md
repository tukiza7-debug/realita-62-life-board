# Contributing

Thanks for considering a contribution to Realita +62: Life Board.

## Setup

```bash
git clone https://github.com/tukiza7-debug/realita-62-life-board.git
cd realita-62-life-board
flutter pub get
flutter gen-l10n
```

Requirements: Flutter 3.24.0 (stable), JDK 17, Android SDK with platform
`android-34` and build-tools.

## Run the tests

Before opening a PR:

```bash
flutter analyze                # must be 0 errors
flutter test                  # all tests must pass
dart format --set-exit-if-changed .
```

Optional but encouraged:

```bash
flutter test integration_test  # if you change screens
flutter run --profile          # if you change anything on the board screen
```

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): summary`. Example:

```
feat(board): pinch-zoom + camera follow
fix(cards): BL07 rent raise timer never decremented
docs(audit): add 5000-game simulation report
test(parity): byte-for-byte fixtures vs legacy Kotlin engine
```

Keep commits small. One logical change per commit.

## Localization rules

Two languages are mandatory: **English** and **Bahasa Indonesia**.

- All UI strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`. NO hardcoded UI text in widget code.
- The Indonesian text is written in **natural** Indonesian (KBBI / Badan Bahasa). No machine translation (no Google Translate, DeepL, AI auto-translate).
- If you add or change a string key, do it in BOTH ARB files in the same commit. The CI l10n parity test (TODO) will fail if a key is missing in either file.
- Cultural terms (UKT, KPR, Pinjol, TAPERA, MBG, Mahar Partai, PHK, OTT KPK, BPJS, PBB) stay as proper nouns in the English version and are explained in `lib/brand/glossary_data.dart` and `docs/GLOSSARY.md`. Source URLs for each term are in `docs/GLOSSARY.md`.
- Indonesian runs ~20–30% longer than English; check the layout doesn't overflow at 200% text scale in both languages.

## Asset rules (audio, fonts, icons, art)

- Original work or CC0 / public domain only. Forbidden: CC-BY-NC, "personal use only", ripped YouTube / Spotify, game / film samples.
- Every third-party asset MUST be added to `CREDITS.md` in the same commit (title, author, source URL, licence, date checked).
- CI fails if an audio file in `assets/audio/` is missing from `CREDITS.md`.

## PR checklist

Before you request review:

- [ ] `flutter analyze` is 0 errors.
- [ ] `flutter test` passes.
- [ ] `dart format --set-exit-if-changed .` reports no changes.
- [ ] Strings added/changed in BOTH `app_en.arb` and `app_id.arb`.
- [ ] Indonesian strings verified against KBBI / Badan Bahasa / official sources; source URLs in `docs/GLOSSARY.md` if a new cultural term.
- [ ] Any new third-party asset is added to `CREDITS.md`.
- [ ] Commit messages follow Conventional Commits.

## Reporting bugs

Open a [GitHub issue](https://github.com/tukiza7-debug/realita-62-life-board/issues/new/choose)
using the Bug Report template. The template requires:

- App version (visible in Settings → About → Version, or `pubspec.yaml` `version:`).
- Android version.
- Device model.
- Language (English / Bahasa Indonesia).
- Orientation when the bug happened.
- Game seed (visible in Settings → About → Copy debug info).
- Steps to reproduce.
- Expected vs actual.
