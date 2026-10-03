package id.realita62.lifeboard.engine

import kotlinx.serialization.Serializable

/**
 * All monetary values are stored in Rupiah *millions* (Rp 1M = Rp 1.000.000).
 * This keeps the numbers small enough to reason about during play, while the
 * HUD formats them with full separators ("Rp 1.000.000" or "Rp 1M").
 */
typealias Rp = Double // millions

@Serializable
enum class Career(val id: String, val grossPayday: Rp, val labelEn: String, val labelId: String) {
    OJOL_DRIVER("ojol", 4.0, "Ojol Driver", "Driver Ojol"),
    DAILY_WORKER("daily", 3.5, "Daily Worker", "Pekerja Harian"),
    SCBD_EMPLOYEE("scbd", 12.0, "SCBD Employee", "Karyawan SCBD"),
    PNS("pns", 9.0, "Civil Servant (PNS)", "PNS"),
    CONTRACTOR("contractor", 8.0, "Contractor", "Kontraktor"),
    POLITICIAN_CLEAN("politician_clean", 7.0, "Politician (Clean)", "Politikus (Bersih)"),
    POLITICIAN_CORRUPT("politician_corrupt", 7.0, "Politician (Corrupt)", "Politikus (Korupsi)");

    val isPolitician: Boolean get() = id.startsWith("politician")
    val isCorrupt: Boolean get() = this == POLITICIAN_CORRUPT

    companion object {
        fun fromId(id: String): Career = entries.first { it.id == id }
    }
}

@Serializable
enum class MaritalStatus { SINGLE, MARRIED_MODEST, MARRIED_LAVISH }

@Serializable
enum class EducationPath(val id: String, val startingCash: Rp, val uktDebt: Rp) {
    COLLEGE("college", startingCash = 2.0, uktDebt = 10.0),
    SMA_SMK("sma_smk", startingCash = 3.0, uktDebt = 0.0);

    companion object {
        fun fromId(id: String): EducationPath = entries.first { it.id == id }
    }
}

@Serializable
enum class Route { NONE, CLEAN, CORRUPT }

@Serializable
enum class RetirementChoice(val id: String) {
    KAMPUNG_JOGJA("jogja"),
    ISLAND_BALI("bali"),
    ELITE_MENTENG("menteng");

    companion object {
        fun fromId(id: String): RetirementChoice = entries.first { it.id == id }
    }
}

@Serializable
data class Child(
    val id: String,
    val ageLaps: Int = 0,
    val isFunded: Boolean = false,         // did the player pay school fees for this child?
    val isPrivateSchool: Boolean = false,
    val legacyFunded: Rp = 0.0,             // accumulated legacy bonus
    val legacyUnfunded: Rp = 0.0
)

@Serializable
data class Asset(
    val id: String,
    val name: String,
    val price: Rp,
    var remainingKpr: Rp = 0.0,
    var kprInterestBase: Float = 0.03f,        // per lap
    var kprInterestBoostLapsLeft: Int = 0,    // laps remaining of +1% boost (event E17)
    var propertyTaxPaid: Boolean = false
) {
    val downPayment: Rp get() = price * 0.20
    val kprPrincipal: Rp get() = price * 0.80
    val netValue: Rp get() = price - remainingKpr
    val hasKpr: Boolean get() = remainingKpr > 0.001
}

@Serializable
data class Player(
    val id: Int,
    val name: String,
    val isAI: Boolean = false,
    var career: Career? = null,
    var education: EducationPath? = null,
    var maritalStatus: MaritalStatus = MaritalStatus.SINGLE,
    val children: MutableList<Child> = mutableListOf(),
    var route: Route = Route.NONE,
    var cash: Rp = 0.0,
    var happiness: Int = 0,                  // H, can go negative
    var position: Int = 0,                  // tile index
    var lapsCompleted: Int = 0,
    val assets: MutableList<Asset> = mutableListOf(),
    var uktDebt: Rp = 0.0,
    var pinjolDebt: Rp = 0.0,                // principal
    var pinjolInterestNextLap: Rp = 0.0,    // precomputed for HUD display
    var insurance: Boolean = false,          // BPJS / private flag
    val tokens: PlayerTokens = PlayerTokens(),
    var corruptionHeat: Int = 0,            // 0..N; P(KPK sting) = heat * 10%
    var skipsNextTurn: Boolean = false,
    var skipsNextPayday: Boolean = false,
    var fuelSubsidyExtraPerRoll: Rp = 0.0,   // event E06
    var fuelSubsidyLapsLeft: Int = 0,
    var sideBusinessLapsLeft: Int = 0,       // event E21
    var sideBusinessIncomePerLap: Rp = 0.0,
    var landlordRentExtraLapsLeft: Int = 0, // BL07
    var landlordRentExtraPerLap: Rp = 0.0,
    var cheapRentDiscountLapsLeft: Int = 0, // GL14
    var cheapRentDiscountPct: Float = 0.0f,
    var retired: Boolean = false,
    var retirement: RetirementChoice? = null,
    var corruptFlagEver: Boolean = false,   // for endgame scoring
    var usedNepotismPerk: Boolean = false
) {
    /** Sum of all debt obligations for the HUD. */
    fun totalDebt(): Rp = uktDebt + pinjolDebt + assets.sumOf { it.remainingKpr }

    /** Net assets (property without KPR) — used in scoring. */
    fun netAssets(): Rp = assets.sumOf { it.netValue }

    val hasPinjol: Boolean get() = pinjolDebt > 0.001
    val hasKpr: Boolean get() = assets.any { it.hasKpr }
    val hasUkt: Boolean get() = uktDebt > 0.001
    val hasNoDebt: Boolean get() = totalDebt() < 0.001

    /** Living cost for the current lap, factoring children and cheap-rent discount. */
    fun livingCostThisLap(baseCost: Rp, perChild: Rp): Rp {
        val raw = baseCost + children.size * perChild
        val discount = if (cheapRentDiscountLapsLeft > 0) raw * cheapRentDiscountPct.toDouble() else 0.0
        val rentExtra = if (landlordRentExtraLapsLeft > 0) landlordRentExtraPerLap else 0.0
        return (raw - discount + rentExtra).coerceAtLeast(0.0)
    }
}

@Serializable
data class PlayerTokens(
    var skipTurnLoss: Int = 0,
    var cancelNegativeEvent: Int = 0,
    var waiveNextSchoolFee: Int = 0,
    var clinicCostCancel: Int = 0
)
