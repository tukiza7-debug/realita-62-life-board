package id.realita62.lifeboard.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.components.Str

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TutorialScreen(app: RealitaApp, locale: AppLocale, nav: NavController) {
    val steps = if (locale == AppLocale.INDONESIAN) listOf(
        "1. Pilih jalur pendidikan: PTN (College) bermula dengan Rp 2M dan utang UKT Rp 10M, atau SMA/SMK bermula dengan Rp 3M tanpa utang.",
        "2. Lemparkan dadu untuk bergerak. Setiap pemain main bergiliran (pass-and-play).",
        "3. Tile PAYDAY (setiap 5 tile) memberi gaji. PNS & SCBD dikenakan potongan Tapera 3%.",
        "4. Tile EVENT menarik kad 'Nasib Warga +62' dengan efek realistis: BBM naik, PHK, OTT KPK, dsb.",
        "5. Tile LUCK menarik kad Good Luck atau Bad Luck secara rawak.",
        "6. Beli aset (Rumah Kampung, Apartemen, Tanah Jogja/Bali, Menteng Mansion) dengan PPN 12% dan KPR 80%.",
        "7. Tile MARRIAGE: pilih pernikahan sederhana (KUA) atau pesta mewah (utang untuk imej sosial).",
        "8. Tile CHILD: setiap anak menambahkan kos hidup berulang. Biayai sekolah untuk bonus Dynasty.",
        "9. Tile MAHAR PARTAI: bayar Rp 15M untuk masuk politik. Pilih jalur BERSIH (untung kecil, +H) atau KORUPSI (cepat kaya, risiko KPK).",
        "10. Pensiun: pilih Jogja, Bali, atau Menteng. Skor = Aset Bersih + Tunai + (H x 0.5M) + Bonus Dynasty. Korupsi dengan H negatif → skor dipotong separuh.",
        "11. Warga Teladan +62: tidak korupsi, tanpa Pinjol di akhir, H positif, pensiun di Jogja/Bali."
    ) else listOf(
        "1. Pick an education path: College (PTN) starts with Rp 2M and Rp 10M UKT debt, or SMA/SMK starts with Rp 3M and no debt.",
        "2. Roll the dice to move. Pass-and-play between 2-4 players on one device.",
        "3. PAYDAY tile (every 5th tile) gives your career's payday. PNS & SCBD employees lose 3% TAPERA.",
        "4. EVENT tiles draw a 'Nasib Warga +62' card with realistic effects: fuel hike, mass layoffs, KPK OTT, etc.",
        "5. LUCK tiles draw a Good Luck or Bad Luck card at random.",
        "6. Buy assets (Kampung House, Apartment, Jogja/Bali Land, Menteng Mansion) with 12% PPN and 80% KPR.",
        "7. MARRIAGE tile: choose Modest (KUA) or Lavish wedding (debt for social image).",
        "8. CHILD tile: each child adds recurring living cost. Fund their education for Dynasty bonus.",
        "9. MAHAR PARTAI tile: pay Rp 15M to enter politics. Choose Clean (low income, +H) or Corrupt (fast cash, KPK risk).",
        "10. Retirement: choose Jogja, Bali, or Menteng. Score = Net Assets + Cash + (H x 0.5M) + Legacy bonus. Corrupt route with negative H halves the score.",
        "11. Warga Teladan +62 (Model Citizen): no corruption, no Pinjol at end, positive H, retire in Jogja/Bali."
    )

    Scaffold(topBar = {
        TopAppBar(
            title = { Text(Str(app, locale, "How to Play", "Cara Bermain")) },
            navigationIcon = { IconButton(onClick = { nav.popBackStack() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            } }
        )
    }) { padding ->
        LazyColumn(modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(steps) { step ->
                Surface(color = MaterialTheme.colorScheme.surface, tonalElevation = 1.dp) {
                    Text(step, modifier = Modifier.padding(12.dp))
                }
            }
        }
    }
}
