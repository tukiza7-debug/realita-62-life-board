package id.realita62.lifeboard.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.engine.Career
import id.realita62.lifeboard.engine.EducationPath
import id.realita62.lifeboard.engine.Player
import id.realita62.lifeboard.engine.SeededRng
import id.realita62.lifeboard.engine.GameState
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.components.Str
import id.realita62.lifeboard.ui.GameViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewGameScreen(app: RealitaApp, locale: AppLocale, nav: NavController) {
    val scope = rememberCoroutineScope()
    var playerCount by remember { mutableStateOf(2) }
    var aiCount by remember { mutableStateOf(0) }
    val names = remember { mutableStateListOf("Player 1", "Player 2", "Player 3", "Player 4") }

    Scaffold(topBar = {
        TopAppBar(
            title = { Text(Str(app, locale, "New Game", "Permainan Baru")) },
            navigationIcon = { IconButton(onClick = { nav.popBackStack() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            } }
        )
    }) { padding ->
        Column(modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)) {

            Text(Str(app, locale, "Players", "Pemain"), style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                (2..4).forEach { n ->
                    FilterChip(
                        selected = playerCount == n,
                        onClick = { playerCount = n; if (aiCount > n - 1) aiCount = n - 1 },
                        label = { Text("$n") }
                    )
                }
            }

            Text(Str(app, locale, "AI opponents", "Lawan AI"), style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                (0..(playerCount - 1)).forEach { n ->
                    FilterChip(
                        selected = aiCount == n,
                        onClick = { aiCount = n },
                        label = { Text("$n") }
                    )
                }
            }

            Text(Str(app, locale, "Player names", "Nama pemain"), style = MaterialTheme.typography.titleMedium)
            for (i in 0 until playerCount) {
                OutlinedTextField(
                    value = names[i],
                    onValueChange = { names[i] = it },
                    label = { Text("Player ${i + 1}") },
                    leadingIcon = {
                        Icon(if (i >= playerCount - aiCount) Icons.Default.SmartToy else Icons.Default.Person,
                             contentDescription = null)
                    },
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(Modifier.height(16.dp))
            Button(
                onClick = {
                    val seed = System.currentTimeMillis()
                    val players = (0 until playerCount).map { i ->
                        Player(
                            id = i,
                            name = names[i].ifBlank { "Player ${i + 1}" },
                            isAI = i >= playerCount - aiCount
                        )
                    }.toMutableList()
                    val state = GameState(seed = seed, players = players)
                    // Initialize with a deterministic RNG so gameplay is reproducible from seed.
                    SeededRng(seed)
                    val stateJson = id.realita62.lifeboard.engine.GameOrchestrator.JSON.encodeToString(
                        GameState.serializer(), state
                    )
                    scope.launch {
                        app.settings.saveGame(stateJson)
                        nav.navigate("game") {
                            popUpTo("menu") { inclusive = false }
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Icon(Icons.Default.PlayArrow, contentDescription = null)
                Spacer(Modifier.width(8.dp))
                Text(Str(app, locale, "Start Game", "Mula Permainan"))
            }
        }
    }
}
