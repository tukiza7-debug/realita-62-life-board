# Changelog

All notable changes to **Realita +62: Life Board** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-10-03

### Added
- Initial release of *Realita +62: Life Board*.
- Clean-architecture Kotlin + Jetpack Compose Android app.
- Deterministic, seeded rules engine (`SeededRng`, `GameEngine`, `CardResolver`, `Movement`, `CardDeck`, `GameOrchestrator`).
- All 70 cards implemented as JSON data:
  - 30 event cards (E01–E30): *Nasib Warga +62* (MBG skimming, fuel subsidy, PHK massal, KPK OTT, PPN shock, mortgage rate reset, etc.).
  - 20 Good Luck cards (GL01–GL20).
  - 20 Bad Luck cards (BL01–BL20).
- 60-tile winding board with fork tiles (education, marriage, asset shop, mahar partai, tender, retirement).
- 7 careers: Ojol Driver, Daily Worker, SCBD Employee, PNS, Contractor, Politician (Clean / Corrupt).
- 4 assets: Kampung House, Apartment, Jogja/Bali Land, Menteng Mansion — with 12% PPN and 80% KPR.
- Family mechanics: marriage (Modest KUA vs Lavish), children, school funding, Dynasty Legacy bonus, Nepotism perk.
- Politician path with Mahar Partai gate (Rp 15M), Clean (+H) vs Corrupt (+heat) routes, KPK sting chance = heat × 10%.
- Retirement fork: Kampung Jogja, Island Bali, Elite Menteng.
- Scoring formula: Net Assets + Cash + (Happiness × Rp 0.5M) + Legacy bonus; corrupt route with negative H halves the score.
- *Warga Teladan +62* (Model Citizen) achievement.
- Localization: English (`values-en/strings.xml`) and Indonesian (`values-in/strings.xml`). Verified against KBBI / Badan Bahasa / Kompas / Tempo / CNN Indonesia / BPJS / DJP / BP Tapera (see `docs/GLOSSARY.md`).
- Settings: language picker, dark theme, sound, haptics, reduced motion. Persisted via DataStore.
- Autosave after every turn. Resume on launch.
- Glossary screen with cultural-term explanations (UKT, KPR, Pinjol, TAPERA, MBG, Mahar Partai, THR, Arisan, Gotong Royong, OTT KPK, BPJS, PBB, PHK, Warung, Kondangan, Mudik).
- Tutorial screen covering all gameplay steps.
- Game Log showing the 50 most recent events.
- GitHub Actions workflow `.github/workflows/build-apk.yml` for building the signed release APK on tag push.

### Tests
- Unit tests for payday + TAPERA, PPN 12% on asset purchase, UKT 2% / KPR 3% / Pinjol 15% interest, fuel-subsidy timer, scoring (including corrupt-halving rule), Dynasty Legacy, save/load round-trip, deterministic RNG, plus one card test per representative event/luck card.
- 1000-game simulation that verifies: games always finish, no NaN/overflow, no single route wins more than ~40%.

### Known Limitations
- Audio: not yet bundled. Synthesized SFX (dice, coins, cards) is planned for v1.1.
- Asset art: uses vector shapes and color tokens only — illustrations and a more vibrant board layout are planned for v1.2.
- Tutorial is text-only; animated tutorial is planned for v1.2.
- No instrumented UI tests yet — only unit tests of the rules engine (see `docs/AUDIT.md`).

[1.0.0]: https://github.com/tukiza7-debug/realita-62-life-board/releases/tag/v1.0.0
