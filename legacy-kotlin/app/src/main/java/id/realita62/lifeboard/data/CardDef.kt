package id.realita62.lifeboard.data

import kotlinx.serialization.Serializable

/**
 * One card definition. Both EN and ID strings live here so the loader can
 * pick at runtime based on the active locale. No hardcoded strings in UI code.
 *
 * `effect` is parsed by CardResolver into concrete mutations on GameState.
 */
@Serializable
data class CardDef(
    val id: String,
    val titleEn: String,
    val titleId: String,
    val flavorEn: String,
    val flavorId: String,
    val effect: String,
    val isLuck: Boolean = false
)

/**
 * Cards are stored in `assets/data/cards.json` and parsed at app start.
 * The file contains 30 event cards (E01..E30) and 40 luck cards
 * (GL01..GL20 / BL01..BL20) = 70 cards total, per the master prompt.
 */
@Serializable
data class CardLibrary(
    val events: List<CardDef>,
    val goodLuck: List<CardDef>,
    val badLuck: List<CardDef>
)
