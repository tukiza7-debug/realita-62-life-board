package id.realita62.lifeboard.engine

import kotlinx.serialization.Serializable

/**
 * Game-wide balance config. Lives in `assets/data/balance.json` so it can be
 * tuned without rebuilding the engine. The values below are the defaults
 * referenced from the master prompt; an audit + 1000-game simulation in
 * docs/AUDIT.md verifies that no single route wins more than ~40%.
 */
@Serializable
data class BalanceConfig(
    val baseLivingCostPerLap: Rp = 3.0,
    val perChildLivingCost: Rp = 1.5,
    val ppnPct: Float = 0.12f,            // 12% on asset purchases
    val taperaPct: Float = 0.03f,         // 3% of gross payday for PNS / SCBD
    val uktInterestPerLapPct: Float = 0.02f,
    val kprInterestBasePerLapPct: Float = 0.03f,
    val pinjolInterestPerLapPct: Float = 0.15f,
    val fuelSubsidyExtraPerRoll: Rp = 0.2,
    val fuelSubsidyLaps: Int = 3,
    val savingsBufferThreshold: Rp = 10.0,
    val badLuckCashReductionPct: Float = 0.25f,
    val goodLuckCashCap: Rp = 5.0,
    val maxGoodLuckPerLap: Int = 2,
    val kpkStingChancePerHeatPct: Float = 0.10f,
    val kpkStingCaughtCashLossPct: Float = 0.50f,
    val kpkStingCaughtHeatLoss: Int = 20,
    val kpkStingCaughtSkips: Int = 2,
    val cleanHappinessBonus: Int = 5,
    val sideBusinessIncomePerLap: Rp = 2.0,
    val sideBusinessLaps: Int = 3,
    val sideBusinessFlopChance: Float = 0.25f,
    val legacyPerFundedChild: Rp = 3.0,
    val legacyPerUnfundedChild: Rp = 0.5,
    val happinessValueInScore: Rp = 0.5,
    val partyDowry: Rp = 15.0,
    val modestWeddingCost: Rp = 1.0,
    val modestWeddingHappiness: Int = 8,
    val lavishWeddingCost: Rp = 8.0,
    val lavishWeddingHappiness: Int = 25,
    val enterCorruptTheftPerLap: Rp = 6.0,
    val enterCorruptHeatPerTheft: Int = 1,
    val corruptRouteFinalHappinessThreshold: Int = 0,
    val corruptRouteFinalScoreDivider: Int = 2,
    val savingThresholdForPositiveHappiness: Rp = 0.0, // any positive net worth counts
    val boardSize: Int = 60
) {
    companion object {
        val DEFAULT = BalanceConfig()
    }
}

/**
 * Permanent, immutable game rules (career table, asset catalogue, etc).
 * Loaded from `assets/data/`. Tunable through balance.json + careers.json + assets.json.
 */
@Serializable
data class CareerDef(
    val id: String,
    val grossPayday: Rp,
    val labelEn: String,
    val labelId: String
)

@Serializable
data class AssetDef(
    val id: String,
    val nameEn: String,
    val nameId: String,
    val price: Rp,
    val kprInterestBasePerLapPct: Float = 0.03f
)

@Serializable
data class AssetCatalogue(
    val items: List<AssetDef> = listOf(
        AssetDef("kampung_house", "Small Kampung House", "Rumah Kampung Kecil", 20.0),
        AssetDef("apartment", "Apartment", "Apartemen", 35.0),
        AssetDef("jogja_land", "Land in Jogja/Bali", "Tanah di Jogja/Bali", 40.0),
        AssetDef("menteng_mansion", "Menteng Mansion", "Rumah Besar Menteng", 120.0)
    )
)
