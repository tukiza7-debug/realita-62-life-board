# Realita +62: Life Board

A Game-of-Life-style family board game that blends classic mechanics with the bittersweet socio-economic and political reality of modern Indonesia.

The goal is not just to get rich. The goal is to **survive** inflation/disinflation, burdensome government policy and the temptation of corruption, and to reach retirement with dignity.

> Indonesian subtitle: *Papan Kehidupan, Edisi Lengkap Dinasti & Survival*

## Features

- Local multiplayer (2–4 players, pass-and-play on one device) and optional solo vs AI (1–3 AI opponents).
- Fully offline. No backend, no accounts, no ads, no analytics.
- **English and Indonesian** localization, switchable at any time. Verified against KBBI, Badan Bahasa, Kompas, Tempo, CNN Indonesia, official sites (BPJS Kesehatan, DJP, BP Tapera) — see `docs/GLOSSARY.md`.
- Clean architecture: deterministic, seeded rules engine (`engine/`), pure-data card & tile library (`data/`), Compose UI (`ui/`), l10n (`l10n/`).
- 70 hand-balanced cards: 30 event cards (*Nasib Warga +62*) + 20 Good Luck + 20 Bad Luck.
- 60-tile winding board with fork tiles (education, marriage, asset shop, mahar partai, retirement).
- Indonesian-inspired palette (batik red, cream, deep teal, gold accent). Light + dark themes.
- Autosave after every turn. Resume on launch.
- Accessibility: large tap targets, colorblind-safe status colors, reduced-motion option.

## Tech Stack

- Kotlin 1.9.24
- Jetpack Compose (Material 3, BOM 2024.06.00)
- AndroidX (Core KTX, Activity, Lifecycle, DataStore Preferences, Navigation Compose)
- kotlinx-serialization-json 1.6.3
- kotlinx-coroutines 1.8.1
- Java 17 + Android Gradle Plugin 8.5.2 + Gradle 8.7
- Min SDK 24, Target SDK 34

### Why Kotlin + Jetpack Compose (not Flutter)?

The master prompt asked us to choose one and justify it. Compose was chosen because:
1. Single-language (Kotlin) for engine + UI — less context-switching and easier to keep the engine deterministic.
2. Compose tooling and Material 3 components are first-party in Android Studio and have stabilized.
3. The engine layer is pure Kotlin (no Android imports), so it can be reused in a future iOS port via Kotlin Multiplatform without touching UI code.

## Build

This repository ships a GitHub Actions workflow (`.github/workflows/build-apk.yml`) that builds a signed release APK on every tag push. See `docs/SPEC.md` for the architecture and `docs/AUDIT.md` for the audit results.

### Local build

Requirements: Android Studio Koala or later, JDK 17, Android SDK with platform `android-34` and `build-tools`.

```bash
# 1. Generate a release keystore (one-time)
keytool -genkeypair -v -keystore realita.keystore \
    -alias realita -keyalg RSA -keysize 2048 -validity 10000

# 2. Export env vars for signing
export REALITA_KEYSTORE_FILE=$PWD/realita.keystore
export REALITA_KEYSTORE_PASSWORD=<your-store-password>
export REALITA_KEY_ALIAS=realita
export REALITA_KEY_PASSWORD=<your-key-password>

# 3. Build
./gradlew assembleRelease
# Output: app/build/outputs/apk/release/app-release.apk
```

If the env vars are not set, the release build falls back to debug signing so you still get an installable APK.

### Download the official APK

The latest signed APK is always available on the [Releases page](https://github.com/tukiza7-debug/realita-62-life-board/releases). It is auto-built by GitHub Actions when a new version tag (`v1.x.y`) is pushed.

## How to Play

Read `docs/SPEC.md` for the full rules, or open the in-game Tutorial screen. Short version:

1. Each player picks an education path: **College (PTN)** starts with Rp 2M and Rp 10M UKT debt, or **SMA/SMK** starts with Rp 3M and no debt.
2. Roll the dice to move. Payday tile (every 5th tile) gives your career's income.
3. **Event tiles** draw *Nasib Warga +62* cards — fuel hikes, mass layoffs, KPK OTT, etc.
4. **Luck tiles** draw Good Luck or Bad Luck at random. Cash losses are reduced by 25% if you have ≥ Rp 10M savings; insurance halves medical bills.
5. Buy assets (Kampung House, Apartment, Jogja/Bali Land, Menteng Mansion) with 12% PPN and 80% KPR.
6. **Marriage tile**: choose Modest (KUA) or Lavish wedding.
7. **Child tile**: each child adds recurring living cost. Fund their education for the Dynasty Legacy bonus (+Rp 3M per funded child).
8. **Mahar Partai gate** (Rp 15M): enter politics. **Clean route** is low-income but happiness-positive; **Corrupt route** gives fast cash but each theft adds Corruption Heat — and KPK stings scale with heat.
9. **Retirement fork**: choose Kampung Jogja, Island Bali, or Elite Menteng. Score = Net Assets + Cash + (Happiness × Rp 0.5M) + Legacy Bonus. Corrupt players with negative Happiness have their score **halved**.
10. **Warga Teladan +62** (Model Citizen) title: no corruption, no Pinjol at the end, positive Happiness, retire in Jogja or Bali.

## Asset Licenses

- All source code is MIT-licensed (see `LICENSE`).
- Launcher icon is original work (vector drawable in `app/src/main/res/drawable/`).
- No third-party audio or image assets are bundled. Audio (when added) will be self-made or royalty-free with attribution in `docs/AUDIT.md`.

## Repository Layout

```
.
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── assets/data/cards.json          ← all 70 card definitions
│       │   ├── java/id/realita62/lifeboard/
│       │   │   ├── engine/                     ← pure-logic rules engine
│       │   │   ├── data/                       ← card & tile definitions (JSON-loaded)
│       │   │   ├── ui/                         ← Compose UI (screens + components + theme + audio)
│       │   │   └── l10n/                        ← AppLocale + Glossary
│       │   └── res/                            ← values / values-en / values-in / themes / drawables / mipmaps
│       ├── test/                               ← unit tests
│       └── androidTest/                        ← instrumented tests
├── docs/
│   ├── SPEC.md                                 ← rules spec
│   ├── AUDIT.md                                ← audit + simulation results
│   └── GLOSSARY.md                             ← verified term translations
├── .github/workflows/build-apk.yml            ← CI that builds & releases the signed APK
├── CHANGELOG.md
├── LICENSE                                     ← MIT
└── README.md                                   ← you are here
```

## License

MIT. See [LICENSE](./LICENSE).
