package id.realita62.lifeboard

import android.app.Application
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import id.realita62.lifeboard.data.CardLibrary
import id.realita62.lifeboard.engine.BalanceConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString
import id.realita62.lifeboard.l10n.AppLocale

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "realita_settings")

class RealitaApp : Application() {
    val settings: SettingsManager by lazy { SettingsManager(this) }
    val cardLibrary: CardLibrary by lazy { loadCardLibrary() }

    private fun loadCardLibrary(): CardLibrary {
        val jsonStr = assets.open("data/cards.json").bufferedReader().use { it.readText() }
        val lib = Json { ignoreUnknownKeys = true }.decodeFromString<CardLibrary>(jsonStr)
        require(lib.events.size == 30) { "Expected 30 event cards, got ${lib.events.size}" }
        require(lib.goodLuck.size == 20) { "Expected 20 good luck cards, got ${lib.goodLuck.size}" }
        require(lib.badLuck.size == 20) { "Expected 20 bad luck cards, got ${lib.badLuck.size}" }
        return lib
    }
}

class SettingsManager(private val context: Context) {
    companion object {
        val LOCALE = stringPreferencesKey("locale")
        val DARK_THEME = booleanPreferencesKey("dark_theme")
        val SOUND_ON = booleanPreferencesKey("sound_on")
        val HAPTICS_ON = booleanPreferencesKey("haptics_on")
        val REDUCED_MOTION = booleanPreferencesKey("reduced_motion")
        val SAVED_GAME = stringPreferencesKey("saved_game")
    }

    val locale: Flow<String> = context.dataStore.data.map { it[LOCALE] ?: AppLocale.default().code }
    val darkTheme: Flow<Boolean> = context.dataStore.data.map { it[DARK_THEME] ?: false }
    val soundOn: Flow<Boolean> = context.dataStore.data.map { it[SOUND_ON] ?: true }
    val hapticsOn: Flow<Boolean> = context.dataStore.data.map { it[HAPTICS_ON] ?: true }
    val reducedMotion: Flow<Boolean> = context.dataStore.data.map { it[REDUCED_MOTION] ?: false }
    val savedGame: Flow<String?> = context.dataStore.data.map { it[SAVED_GAME] }

    suspend fun setLocale(code: String) = context.dataStore.edit { it[LOCALE] = code }
    suspend fun setDarkTheme(on: Boolean) = context.dataStore.edit { it[DARK_THEME] = on }
    suspend fun setSoundOn(on: Boolean) = context.dataStore.edit { it[SOUND_ON] = on }
    suspend fun setHapticsOn(on: Boolean) = context.dataStore.edit { it[HAPTICS_ON] = on }
    suspend fun setReducedMotion(on: Boolean) = context.dataStore.edit { it[REDUCED_MOTION] = on }
    suspend fun saveGame(json: String) = context.dataStore.edit { it[SAVED_GAME] = json }
    suspend fun clearSave() = context.dataStore.edit { it.remove(SAVED_GAME) }
}
