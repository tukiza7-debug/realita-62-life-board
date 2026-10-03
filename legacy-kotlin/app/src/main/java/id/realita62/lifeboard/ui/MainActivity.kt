package id.realita62.lifeboard.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.lifecycleScope
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.screens.RealitaNavGraph
import id.realita62.lifeboard.ui.theme.RealitaTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val app = application as RealitaApp
        setContent {
            val darkTheme by app.settings.darkTheme.collectAsState(initial = false)
            val localeCode by app.settings.locale.collectAsState(initial = "en")
            val locale = AppLocale.fromCode(localeCode)
            RealitaTheme(darkTheme = darkTheme) {
                RealitaNavGraph(app, locale)
            }
        }
    }
}
