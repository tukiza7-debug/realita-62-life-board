# Realita +62: Life Board — Specification

This document is the authoritative rules spec for the engine. The engine is
written against this spec; every test traces back to a rule here.

## 1. Units

All monetary values are stored in **Rupiah millions** (Rp 1M = Rp 1.000.000).
Happiness is a signed integer (H, can be negative).

## 2. Player State

Per player: Cash, Debt (UKT, KPR, Pinjol tracked separately), Assets,
Net Assets, Happiness Points (H), Career, Marital status, Children count,
Route (Clean / Corrupt / None), tokens (skip-turn-loss, cancel-negative-event,
waive-next-school-fee, clinic-cost-cancel), insurance flag (BPJS/private),
Corruption Heat, retired flag, retirement choice.

## 3. Education Fork (Start Tile)

| Path | Cash | UKT debt | Career options |
| --- | --- | --- | --- |
| College (PTN) | Rp 2M | Rp 10M | SCBD Employee, PNS, Contractor |
| SMA/SMK | Rp 3M | Rp 0 | Ojol Driver, Daily Worker |

## 4. Careers

| Career | Gross payday | Notes |
| --- | --- | --- |
| Ojol Driver | Rp 4M | Hit directly by "Fuel Subsidy Removed" |
| Daily Worker | Rp 3.5M | Same exposure |
| SCBD Employee | Rp 12M | Vulnerable to layoffs |
| PNS | Rp 9M | Stable, small efficiency cuts |
| Contractor | Rp 8M | Access to tender cards (skim risk) |
| Politician (Clean) | Rp 7M | Low income, happiness-positive, mocked by the public |
| Politician (Corrupt) | Rp 7M + stolen project funds | Fast cash, KPK risk |

## 5. Per-Lap Economy

- **TAPERA:** PNS and SCBD Employee lose 3% of gross payday per lap.
- **PPN 12%:** applies to every asset purchase (`price × 1.12`).
- **Base living cost per lap:** Rp 3M, plus Rp 1.5M per child.
- **Interest per lap:** UKT 2%, KPR 3%, Pinjol 15%.
- **Fuel Subsidy Removed (event E06):** Ojol/Daily Worker pay +Rp 0.2M per
  dice roll for 3 laps.

## 6. Assets

| Asset | Price |
| --- | --- |
| Small kampung house | Rp 20M |
| Apartment | Rp 35M |
| Land in Jogja/Bali | Rp 40M |
| Menteng mansion | Rp 120M |

20% down payment, remainder as KPR. PPN 12% on price. Property tax event
(E16) reduces 1% of asset value.

## 7. Family

- **Marriage tile:** Modest KUA wedding (Rp 1M, +8H) or Lavish Traditional
  Party (Rp 8M, +25H). If lavish cash goes negative, the difference becomes
  Pinjol debt.
- **Children:** each child adds Rp 1.5M per lap, exposes player to school-fee
  cards (E12, BL13), and is a precondition for many cards (E01, E25, GL10).
- **Dynasty mechanic:** at retirement, each funded child adds Rp 3M Legacy
  bonus; each unfunded child adds Rp 0.5M. Politician players may trigger a
  Nepotism Perk for quick cash, which costs H and halves their funded Legacy
  bonus.
- **Warga Teladan +62:** no corruption, no Pinjol at the end, positive H,
  retire in Jogja or Bali.

## 8. Politician Path

- Reachable via the Mahar Partai gate tile by paying Rp 15M.
- **Clean Route:** modest income, bonus H from honest card outcomes, public
  mockery cards (E27) still appear.
- **Corrupt Route:** each lap may "steal project funds" for Rp 6M fast cash,
  but each theft adds +1 Corruption Heat. Heat feeds the KPK sting probability
  (`P = heat × 10%`). Caught: lose 50% cash, -20H, lose 2 turns.

## 9. Cards

- 30 event cards (E01–E30): drawn on Event tiles. Effects depend on player
  status. Some require a player choice (E02, E09, E11, E12, E18, E20, E21,
  E22, E30) — the UI must prompt.
- 40 luck cards (GL01–GL20 / BL01–BL20): drawn on Luck tiles.
  - Savings buffer: ≥ Rp 10M cash → Bad Luck cash loss reduced by 25%.
  - Insurance (BPJS/private) halves medical cards (BL06, BL16).
  - Good Luck gain is capped at Rp 5M per card; max 2 Good Luck cards per
    player per lap.
  - "Skip" effects are stored as one-use tokens.

## 10. Board

~60 tiles on a winding path: Start (Education fork), Education, Career tiles,
Payday, Event, Luck, Marriage, Child, Asset Shop, Mahar Partai Gate, Tender,
Retirement fork. Landmarks: SCBD skyline, kampung streets, Menteng, Jogja,
Bali. Tile data lives in JSON (`assets/data/...` or `BoardFactory.default()`).

## 11. Scoring

```
score = netAssets + cash + (happiness × 0.5) + legacyBonus
```

If the player ever took the Corrupt Route and final H is negative, the score
is **halved**.

## 12. RNG

All randomness goes through `SeededRng`. The engine never reads
`Math.random()` or `System.currentTimeMillis()` for gameplay decisions.
Same seed → same game (verifiable in tests and 1000-game simulations).

## 13. Save / Load

Autosave after every turn. State is serialized with `kotlinx-serialization`
to a single JSON string stored in DataStore preferences. Resume on launch.

## 14. Localization

Two languages: **English** (`en`) and **Indonesian** (`id`). Default is device
language; switchable in Settings. All strings live in resource files
(`values/strings.xml`, `values-en/strings.xml`, `values-in/strings.xml`),
never hardcoded in UI logic. Number/currency formatting: Indonesian
"Rp 1.000.000" or "Rp 1 juta"; English "Rp 1,000,000" or "Rp 1M".

Translation method (strict, per master prompt section 11.4):
1. No Google Translate / DeepL / Bing / AI auto-translation for game text.
2. Vocabulary verified against KBBI, Badan Bahasa/PUEBI, Kompas, Tempo,
   Detik, CNN Indonesia, official sites (BPJS Kesehatan, DJP, Kemenkeu,
   BP Tapera), Indonesian Wikipedia.
3. Natural everyday Indonesian with light humor. No word-for-word calques.
   Indonesian terms retained as proper nouns in English; explained once
   in the Glossary screen.
4. GLOSSARY.md lists each term, chosen wording, and the source URL.
