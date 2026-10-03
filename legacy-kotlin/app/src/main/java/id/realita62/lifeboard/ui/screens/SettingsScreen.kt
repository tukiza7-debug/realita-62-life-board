package id.realita62.lifeboard.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.components.Str
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(app: RealitaApp, locale: AppLocale, nav: NavController) {
    val darkTheme by app.settings.darkTheme.collectAsState(initial = false)
    val soundOn by app.settings.soundOn.collectAsState(initial = true)
    val hapticsOn by app.settings.hapticsOn.collectAsState(initial = true)
    val reducedMotion by app.settings.reducedMotion.collectAsState(initial = false)
    val scope = rememberCoroutineScope()
    var currentLocale by remember { mutableStateOf(locale) }

    Scaffold(topBar = {
        TopAppBar(
            title = { Text(Str(app, locale, "Settings", "Pengaturan")) },
            navigationIcon = { IconButton(onClick = { nav.popBackStack() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            } }
        )
    }) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(Str(app, locale, "Language", "Bahasa"), style = MaterialTheme.typography.titleMedium)
            Row {
                FilterChip(
                    selected = currentLocale == AppLocale.ENGLISH,
                    onClick = { currentLocale = AppLocale.ENGLISH; scope.launch { app.settings.setLocale("en") } },
                    label = { Text("English") }
                )
                Spacer(Modifier.width(8.dp))
                FilterChip(
                    selected = currentLocale == AppLocale.INDONESIAN,
                    onClick = { currentLocale = AppLocale.INDONESIAN; scope.launch { app.settings.setLocale("id") } },
                    label = { Text("Bahasa Indonesia") }
                )
            }
            Spacer(Modifier.height(16.dp))

            SwitchRow(app, locale, "Dark theme", "Tema gelap", darkTheme) { scope.launch { app.settings.setDarkTheme(it) } }
            SwitchRow(app, locale, "Sound", "Suara", soundOn) { scope.launch { app.settings.setSoundOn(it) } }
            SwitchRow(app, locale, "Haptics", "Getar", hapticsOn) { scope.launch { app.settings.setHapticsOn(it) } }
            SwitchRow(app, locale, "Reduced motion", "Kurangi animasi", reducedMotion) { scope.launch { app.settings.setReducedMotion(it) } }
        }
    }
}

@Composable
private fun ColumnScope.SwitchRow(
    app: RealitaApp, locale: AppLocale, en: String, id: String,
    checked: Boolean, onCheckedChange: (Boolean) -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp
    ) {
        Row(
            modifier = Modifier.padding(16.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Text(Str(app, locale, en, id))
            Switch(checked = checked, onCheckedChange = onCheckedChange)
        }
    }
}
