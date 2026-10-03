package id.realita62.lifeboard.engine

import kotlinx.serialization.Serializable

@Serializable
enum class TileType(val id: String) {
    START("start"),
    EDUCATION_FORK("education_fork"),
    PAYDAY("payday"),
    EVENT("event"),
    LUCK("luck"),
    MARRIAGE("marriage"),
    CHILD("child"),
    ASSET_SHOP("asset_shop"),
    MAHAR_PARTAI_GATE("mahar_partai_gate"),
    TENDER("tender"),
    RETIREMENT_FORK("retirement_fork"),
    BLANK("blank");

    companion object { fun fromId(id: String) = entries.first { it.id == id } }
}

@Serializable
data class Tile(
    val index: Int,
    val type: TileType,
    val nameEn: String = "",
    val nameId: String = "",
    val landmarkEn: String = "",
    val landmarkId: String = ""
)

/**
 * The board: a list of ~60 tiles in a winding path from start to retirement.
 * Tile data lives in JSON (assets/data/board.json); here is the default layout.
 *
 * Layout:
 *   0       - Start (with Education fork)
 *   1..N    - winding path with payday / event / luck / marriage / child / asset / tender tiles
 *   Last    - Retirement fork (Jogja / Bali / Menteng)
 */
object BoardFactory {
    fun default(size: Int = 60): List<Tile> {
        val tiles = mutableListOf<Tile>()
        // Tile 0: Start + Education fork
        tiles += Tile(0, TileType.START,
            nameEn = "Start", nameId = "Mulai",
            landmarkEn = "Your story begins", landmarkId = "Cerita Anda dimulai")

        // Tiles 1..size-2: a varied path. Insert forks at sensible positions.
        // Every 5th tile is payday; every 6th is event; every 9th is luck; etc.
        for (i in 1 until size - 1) {
            val t = when {
                i == 6 -> TileType.MARRIAGE
                i == 12 -> TileType.CHILD
                i == 18 -> TileType.ASSET_SHOP
                i == 24 -> TileType.MAHAR_PARTAI_GATE
                i == 30 -> TileType.TENDER
                i == 36 -> TileType.MARRIAGE
                i == 42 -> TileType.CHILD
                i == 48 -> TileType.ASSET_SHOP
                i % 5 == 0 -> TileType.PAYDAY
                i % 7 == 0 -> TileType.LUCK
                i % 3 == 0 -> TileType.EVENT
                else -> TileType.BLANK
            }
            val (en, id) = landmarkFor(i)
            tiles += Tile(i, t, nameEn = en.first, nameId = id.first,
                landmarkEn = en.second, landmarkId = id.second)
        }
        // Last tile: Retirement fork
        tiles += Tile(size - 1, TileType.RETIREMENT_FORK,
            nameEn = "Retirement Fork", nameId = "Percabangan Pensiun",
            landmarkEn = "Choose your retirement", landmarkId = "Pilih masa pensiun Anda")
        return tiles
    }

    private fun landmarkFor(i: Int): Pair<Pair<String, String>, Pair<String, String>> {
        val namePairs = listOf(
            "SCBD Skyline" to "Pemandangan SCBD",
            "Kampung Streets" to "S gang Kampung",
            "Menteng" to "Menteng",
            "Jogja" to "Jogja",
            "Bali" to "Bali",
            "Warung Pojok" to "Warung Pojok",
            "Pasar Tradisional" to "Pasar Tradisional",
            "Kantor Lurah" to "Kantor Lurah",
            "Stasiun Kereta" to "Stasiun Kereta",
            "Halte TransJ" to "Halte TransJakarta"
        )
        val (en, id) = namePairs[i % namePairs.size]
        return ("Tile $i" to en) to ("Tile $i" to id)
    }
}
