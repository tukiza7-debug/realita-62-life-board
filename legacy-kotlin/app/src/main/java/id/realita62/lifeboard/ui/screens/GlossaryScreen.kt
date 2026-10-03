package id.realita62.lifeboard.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.l10n.Glossary
import id.realita62.lifeboard.ui.components.Str

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GlossaryScreen(app: RealitaApp, locale: AppLocale, nav: NavController) {
    Scaffold(topBar = {
        TopAppBar(
            title = { Text(Str(app, locale, "Glossary", "Glosarium")) },
            navigationIcon = { IconButton(onClick = { nav.popBackStack() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            } }
        )
    }) { padding ->
        LazyColumn(
            modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(Glossary.terms) { term ->
                GlossaryCard(app, locale, term)
            }
        }
    }
}

@Composable
private fun GlossaryCard(app: RealitaApp, locale: AppLocale, term: Glossary.Term) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                if (locale == AppLocale.INDONESIAN) term.shortId else term.shortEn,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.height(8.dp))
            Text(
                if (locale == AppLocale.INDONESIAN) term.longId else term.longEn,
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}
