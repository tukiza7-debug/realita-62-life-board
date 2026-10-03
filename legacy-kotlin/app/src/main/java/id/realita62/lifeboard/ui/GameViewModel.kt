package id.realita62.lifeboard.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.engine.BalanceConfig
import id.realita62.lifeboard.engine.BoardFactory
import id.realita62.lifeboard.engine.GameOrchestrator
import id.realita62.lifeboard.engine.GameState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first

class GameViewModelFactory(private val app: RealitaApp) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return GameViewModel(app) as T
    }
}

/**
 * Holds the active [GameOrchestrator] and exposes a tick() function the UI
 * calls to drive turns. State changes are surfaced through a StateFlow so
 * Compose recomposes automatically.
 */
class GameViewModel(private val app: RealitaApp) : ViewModel() {

    private val _orchestrator = MutableStateFlow<GameOrchestrator?>(null)
    val orchestrator: StateFlow<GameOrchestrator?> = _orchestrator.asStateFlow()

    private val _lastEvents = MutableStateFlow<List<String>>(emptyList())
    val lastEvents: StateFlow<List<String>> = _lastEvents.asStateFlow()

    private val _needsEducationFork = MutableStateFlow(false)
    val needsEducationFork: StateFlow<Boolean> = _needsEducationFork.asStateFlow()

    private val _currentPlayerIdx = MutableStateFlow(0)
    val currentPlayerIdx: StateFlow<Int> = _currentPlayerIdx

    suspend fun loadOrInitGame() {
        val saved = app.settings.savedGame.first()
        if (saved != null) {
            val state = GameOrchestrator.JSON.decodeFromString(GameState.serializer(), saved)
            val orch = GameOrchestrator(state, BalanceConfig.DEFAULT, BoardFactory.default(), app.cardLibrary)
            _orchestrator.value = orch
            _needsEducationFork.value = state.players.any { it.career == null }
            _currentPlayerIdx.value = state.currentPlayerIdx
        } else {
            // No saved game — bounce back to New Game screen.
            _orchestrator.value = null
        }
    }

    fun setEducationPath(playerIdx: Int, path: id.realita62.lifeboard.engine.EducationPath) {
        val orch = _orchestrator.value ?: return
        orch.setEducation(playerIdx, path)
        // After picking the path, the player picks a career if College.
        flush()
    }

    fun assignCareer(playerIdx: Int, career: id.realita62.lifeboard.engine.Career) {
        val orch = _orchestrator.value ?: return
        orch.assignCareer(playerIdx, career)
        if (orch.state.players.all { it.career != null }) {
            orch.startGame()
        }
        flush()
    }

    fun tick(): id.realita62.lifeboard.engine.TurnResult {
        val orch = _orchestrator.value ?: return id.realita62.lifeboard.engine.TurnResult(emptyList(), turnDone = false, gameOver = false)
        val result = orch.takeTurn()
        _lastEvents.value = result.events.map { it::class.simpleName ?: "Event" }
        _currentPlayerIdx.value = orch.state.currentPlayerIdx
        return result
    }

    fun applyChoice(cardId: String, choice: String) {
        val orch = _orchestrator.value ?: return
        val card = orch.cardLibrary.events.firstOrNull { it.id == cardId }
            ?: orch.cardLibrary.goodLuck.firstOrNull { it.id == cardId }
            ?: orch.cardLibrary.badLuck.firstOrNull { it.id == cardId }
            ?: return
        orch.applyChoiceAndContinue(card, choice)
        flush()
    }

    fun applyMarriage(lavish: Boolean) {
        _orchestrator.value?.applyMarriage(lavish)
        flush()
    }

    fun applyAssetPurchase(assetId: String) {
        _orchestrator.value?.applyAssetPurchase(assetId)
        flush()
    }

    fun applyMaharPartai(enter: Boolean, corrupt: Boolean = false) {
        _orchestrator.value?.applyMaharPartai(enter, corrupt)
        flush()
    }

    fun applyRetirement(choice: id.realita62.lifeboard.engine.RetirementChoice) {
        _orchestrator.value?.applyRetirement(choice)
        flush()
    }

    fun flush() {
        _orchestrator.value = _orchestrator.value // re-trigger StateFlow emission
        _currentPlayerIdx.value = _orchestrator.value?.state?.currentPlayerIdx ?: 0
    }
}
