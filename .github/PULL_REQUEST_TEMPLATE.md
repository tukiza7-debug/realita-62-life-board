## Pull Request checklist

Please confirm before requesting review:

- [ ] `flutter analyze` reports 0 errors.
- [ ] `flutter test` passes.
- [ ] `dart format --set-exit-if-changed .` reports no changes.
- [ ] Any new or changed UI string is added in BOTH `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`.
- [ ] Indonesian strings are verified against KBBI / Badan Bahasa / official sources; no machine translation.
- [ ] Any new third-party asset (audio, font, icon, art) is added to `CREDITS.md` with source URL and licence.
- [ ] Commit messages follow Conventional Commits.
- [ ] The change does not break the deterministic RNG parity (same seed → same game) with the legacy Kotlin engine in `legacy-kotlin/`.

## Summary

<!-- One paragraph: what does this PR do and why? -->

## Test plan

<!-- How did you verify the change? Include command output where useful. -->

## Screenshots / recordings (if UI change)

<!-- Drag images here. For text-density check, include both EN and ID at 200% font scale. -->
