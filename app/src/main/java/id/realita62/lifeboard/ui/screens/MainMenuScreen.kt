package id.realita62.lifeboard.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.components.Str

@Composable
fun MainMenuScreen(app: RealitaApp, locale: AppLocale, nav: NavController) {
    Scaffold(topBar = {
        TopAppBar(title = { Text("Realita +62", style = MaterialTheme.typography.headlineMedium) })
    }) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically)
        ) {
            Text(
                "Life Board",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                "Papan Kehidupan — Edisi Lengkap Dinasti & Survival",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Spacer(Modifier.height(24.dp))
            MenuButton(app, locale, Icons.Default.PlayArrow, "main_menu_new_game", "menu_new_game") { nav.navigate("new_game") }
            MenuButton(app, locale, Icons.Default.History, "main_menu_resume", "menu_resume") { nav.navigate("game") }
            MenuButton(app, locale, Icons.Default.School, "main_menu_tutorial", "menu_tutorial") { nav.navigate("tutorial") }
            MenuButton(app, locale, Icons.Default.Help, "main_menu_glossary", "menu_glossary") { nav.navigate("glossary") }
            MenuButton(app, locale, Icons.Default.Settings, "main_menu_settings", "menu_settings") { nav.navigate("settings") }
        }
    }
}

@Composable
private fun MenuButton(
    app: RealitaApp, locale: AppLocale, icon: androidx.compose.ui.graphics.vector.ImageVector,
    enKey: String, idKey: String, onClick: () -> Unit
) {
    Button(onClick = onClick, modifier = Modifier.fillMaxWidth().height(56.dp)) {
        Icon(icon, contentDescription = null)
        Spacer(Modifier.width(12.dp))
        Text(Str(app, locale, enKey, idKey))
    }
}
