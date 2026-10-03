# Brand — Realita +62: Life Board

## 1. Concept sketches (3 considered, 1 picked)

### Concept A — Winding "62" path (PICKED)
The digits "62" rendered as a winding board path. The "6" is three-quarters of a circle (a tile track curving back on itself), the "2" is a half-arc plus a base and a diagonal stroke. A small pawn sits on the lower-left of the "6" track. Reads instantly as "62" + "board game" + "pawn".

Why picked: it ties the brand mark directly to the gameplay mechanic (a board with a path) and to the country code (+62). It also reads at 48 px without losing the "6" inner curve or the "2" diagonal.

### Concept B — Die with kawung/parang pattern (rejected)
A six-sided die whose face carries an original kawung or parang-inspired geometric pattern. Strong culturally, but a die doesn't communicate "board" — the game's central mechanic is the winding path, not the dice. Harder to read at 48 px because the die-face pattern becomes a smudge.

### Concept C — Pawn on a tile path (rejected)
A pawn standing on a serpentine tile path. Communicates "board game" clearly but loses the "+62" identity entirely. A pure pawn also collides visually with too many other board-game brands.

## 2. Final logo

The final mark is in `assets/brand/realita_symbol.svg` (master) and
`assets/brand/realita_horizontal.svg` (lockup with wordmark). The launcher
icon (Android adaptive + monochrome + legacy vector fallback) is generated
from the same source via `android/app/src/main/res/drawable/ic_launcher_foreground.xml`.

Palette (from the app design system):

| Token | Hex | Use |
|---|---|---|
| batik red | `#B31919` | Background of the mark; saturated, distinct from any national flag |
| cream (putih) | `#FFF8E7` | Foreground "62" digits; high-contrast on red, WCAG AA on batik red background |
| deep teal | `#0E5A4F` | Subtle shadow under the "62" (decorative only, 25% opacity) |
| gold accent | `#D4A23A` | Pawn on the tile; warm, matches the "treasure/winning" connotation |
| charcoal | `#1F1F1F` | Wordmark text on light backgrounds |
| dark surface | `#111827` | Dark-theme background |
| dark on-surface | `#E5E5E5` | Dark-theme foreground |

Typography for the wordmark is "Inter" or system sans-serif. No custom font is bundled in v2.0.0 (the system font stack renders cleanly on all Android densities). v2.1 will bundle an OFL-licensed display font for the wordmark.

## 3. Forbidden in the brand

Per master prompt section 4.1:

- ❌ Garuda Pancasila / Indonesian state emblem.
- ❌ Indonesian national flag.
- ❌ Monopoly / Game of Life / any existing board-game imagery.
- ❌ Any real brand marks.
- ❌ Emoji, photos, traced images.

## 4. Variants produced

- Symbol-only (`realita_symbol.svg`) — square, 108×108 viewBox.
- Horizontal lockup (`realita_horizontal.svg`) — 320×108 viewBox with wordmark.
- Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`) — `batik_red` background + symbol foreground + monochrome layer for Android 13 themed icons.
- Vector-drawn fallback for API 24–25 (`mipmap-anydpi/ic_launcher.xml`).
- Custom-painted in-app version (`lib/ui/main_menu_screen_imports.dart` — `LogoPainter`).

## 5. Reproducibility

The launcher icon PNGs/mipmaps can be regenerated from the master SVG via
the `tool/export_icons.dart` script (TODO for v2.1). For v2.0.0, the Android
adaptive icon uses XML drawables directly (no PNG round-trip), so the source
SVG and the runtime icon stay in sync.

## 6. Proof (UNVERIFIED in this v2.0.0 commit)

- `aapt dump badging` on a released APK — UNVERIFIED (no signed release yet).
- Real screenshot of the icon on a launcher — UNVERIFIED (no device).
- Golden test renders at 48 / 96 / 192 px in light + dark — UNVERIFIED (v2.1).

These items are tracked in `docs/AUDIT.md` §10.
