# CREDITS

Per master prompt section 9: every third-party asset (audio, fonts,
icons, libraries) is listed here with source URL and licence. CI fails
if an audio file in `assets/audio/` is missing from this file.

## Audio

No audio files are bundled in v2.0.0. Synthesized SFX (dice, coin, card
flip, button tap) are tracked as v2.1 work; they will be self-made via a
`tool/synth_sfx.dart` script (CC0) and credited here when added.

When real audio is added:
- Title, author, source URL, licence, date checked.

Forbidden (per master prompt section 9):
- CC-BY-NC.
- "Personal use only" sources.
- Ripped YouTube / Spotify audio.
- Game / film samples.
- Sources with unclear terms.

## Fonts

No custom fonts are bundled in v2.0.0. The wordmark uses the system
sans-serif (Inter on modern Android; fallback to Helvetica / Arial).
v2.1 will bundle an OFL-licensed display font for the wordmark, with
the licence entry here.

## Icons

- Material Icons — bundled via `flutter` SDK; licence: Apache 2.0.
- Custom logo — original hand-authored SVG; copyright MIT (project
  licence).

## Code libraries

| Package | Version | Licence | Source |
|---|---|---|---|
| flutter | 3.24.0 (stable) | BSD-3-Clause | https://flutter.dev/ |
| flutter_localizations | (bundled) | BSD-3-Clause | https://api.flutter.dev/ |
| cupertino_icons | ^1.0.8 | MIT | https://pub.dev/packages/cupertino_icons |
| shared_preferences | ^2.3.2 | BSD-3-Clause | https://pub.dev/packages/shared_preferences |
| provider | ^6.1.2 | MIT | https://pub.dev/packages/provider |
| collection | ^1.18.0 | BSD-3-Clause | https://pub.dev/packages/collection |

All package licences are compatible with the project's MIT licence.

## Tools

- Flutter SDK — BSD-3-Clause, https://flutter.dev/.
- Dart SDK — BSD-3-Clause, https://dart.dev/.
- GitHub Actions runners — provided by GitHub.
- `subosito/flutter-action` — MIT, https://github.com/subosito/flutter-action.
- `softprops/action-gh-release` — MIT, https://github.com/softprops/action-gh-release.
- `lycheeverse/lychee-action` — MIT, https://github.com/lycheeverse/lychee-action.
- `actions/checkout`, `actions/setup-java`, `actions/cache`, `actions/upload-artifact` — MIT, https://github.com/actions.

## Acknowledgements

The legacy Kotlin implementation in `legacy-kotlin/` was the behavioural
reference for the Dart engine port; its `SeededRng`, `GameEngine`,
`CardResolver`, `CardDeck`, `Movement`, `GameOrchestrator`, `Board`,
`BalanceConfig`, and `Models` files were ported method-by-method with
29 unit tests verifying RNG parity.
