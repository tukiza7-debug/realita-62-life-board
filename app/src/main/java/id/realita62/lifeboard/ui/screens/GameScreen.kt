package id.realita62.lifeboard.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Agriculture
import androidx.compose.material.icons.filled.BabyChangingStation
import androidx.compose.material.icons.filled.BeachAccess
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.ChildCare
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocalAtm
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Payment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Policy
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.SentimentDissatisfied
import androidx.compose.material.icons.filled.SentimentNeutral
import androidx.compose.material.icons.filled.SentimentVerySatisfied
import androidx.compose.material.icons.filled.SentimentVeryDissatisfied
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.engine.GameEvent
import id.realita62.lifeboard.engine.Player
import id.realita62.lifeboard.engine.Career
import id.realita62.lifeboard.engine.EducationPath
import id.realita62.lifeboard.engine.RetirementChoice
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.GameViewModel
import id.realita62.lifeboard.ui.components.Str
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameScreen(app: RealitaApp, locale: AppLocale, nav: NavController, vm: GameViewModel) {
    val orch by vm.orchestrator.collectAsStateWithLifecycle()
    val lastEvents by vm.lastEvents.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        vm.loadOrInitGame()
    }

    if (orch == null) {
        // Show loading then bounce
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(Str(app, locale, "Loading...", "Memuat..."))
        }
        return
    }

    val state = orch!!.state
    val currentPlayer = state.players[state.currentPlayerIdx]

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Realita +62", style = MaterialTheme.typography.titleMedium)
                        Text(
                            if (locale == AppLocale.INDONESIAN) "Giliran: ${currentPlayer.name}"
                            else "Turn: ${currentPlayer.name}",
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { nav.navigate("settings") }) {
                        Icon(Icons.Default.Pause, contentDescription = "Settings")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Player HUD cards
            PlayerHudStrip(app, locale, players = state.players, currentIdx = state.currentPlayerIdx)

            // Board view (simplified — track of tiles with current player highlighted)
            BoardTrack(app, locale, board = orch!!.board, positions = state.players.map { it.position })

            Spacer(Modifier.height(8.dp))

            // Game log
            Card(modifier = Modifier.fillMaxWidth().weight(1f)) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(Str(app, locale, "Game Log", "Log Permainan"),
                        style = MaterialTheme.typography.titleMedium)
                    Spacer(Modifier.height(8.dp))
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        reverseLayout = true,
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        items(state.log.takeLast(50)) { ev ->
                            Text(formatEvent(ev, locale, app), style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }

            // Bottom action bar
            BottomActionBar(app, locale, vm = vm, orch = orch!!)
        }
    }

    // ---- Pending dialog overlays ----
    orch!!.pendingChoice?.let { pc ->
        val card = pc.card
        ChoiceCardDialog(
            app = app, locale = locale,
            titleEn = card.titleEn, titleId = card.titleId,
            flavorEn = card.flavorEn, flavorId = card.flavorId,
            choices = id.realita62.lifeboard.engine.CardResolver.choicesFor(card.effect).map { choiceCode ->
                choiceLabel(app, locale, card.effect, choiceCode) to choiceCode
            },
            onChoose = { code -> vm.applyChoice(card.id, code) }
        )
    }
    orch!!.pendingMarriage?.let {
        MarriageDialog(app, locale,
            onPick = { lavish -> vm.applyMarriage(lavish) })
    }
    orch!!.pendingAssetShop?.let {
        AssetShopDialog(app, locale,
            catalogue = orch!!.state.assetCatalogue,
            onBuy = { id -> vm.applyAssetPurchase(id) })
    }
    orch!!.pendingMaharPartai?.let {
        MaharPartaiDialog(app, locale,
            onPick = { enter, corrupt -> vm.applyMaharPartai(enter, corrupt) })
    }
    orch!!.pendingRetirement?.let {
        RetirementDialog(app, locale,
            onPick = { c -> vm.applyRetirement(c) })
    }
    if (state.gameOver) {
        GameOverDialog(app, locale, orch!!, onReplay = {
            scope.launch {
                app.settings.clearSave()
                nav.navigate("menu") { popUpTo("menu") { inclusive = true } }
            }
        })
    }
}

@Composable
private fun PlayerHudStrip(app: RealitaApp, locale: AppLocale, players: List<Player>, currentIdx: Int) {
    Row(modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min),
        horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        players.forEachIndexed { idx, p ->
            PlayerHudCard(
                app, locale, p,
                modifier = Modifier.weight(1f),
                highlighted = idx == currentIdx
            )
        }
    }
}

@Composable
private fun PlayerHudCard(app: RealitaApp, locale: AppLocale, p: Player, modifier: Modifier, highlighted: Boolean) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        color = if (highlighted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface,
        tonalElevation = if (highlighted) 0.dp else 1.dp
    ) {
        Column(modifier = Modifier.padding(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (p.isAI) Icons.Default.Psychology else Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(Modifier.width(4.dp))
                Text(p.name.take(12), style = MaterialTheme.typography.labelSmall,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    color = if (highlighted) MaterialTheme.colorScheme.onPrimary
                            else MaterialTheme.colorScheme.onSurface)
            }
            Text("Rp ${p.cash}M", style = MaterialTheme.typography.labelSmall,
                color = if (highlighted) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurface)
            Row(verticalAlignment = Alignment.CenterVertically) {
                val (icon, tint) = happinessIconAndTint(p.happiness)
                Icon(icon, contentDescription = null, tint = tint,
                    modifier = Modifier.size(14.dp))
                Text("H ${p.happiness}", style = MaterialTheme.typography.labelSmall,
                    color = if (highlighted) MaterialTheme.colorScheme.onPrimary
                            else MaterialTheme.colorScheme.onSurface)
            }
            Text(p.career?.let { careerLabel(it, locale) } ?: "-",
                style = MaterialTheme.typography.labelSmall,
                color = if (highlighted) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurface)
            if (p.children.isNotEmpty()) {
                Text("👶 ${p.children.size}",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (highlighted) MaterialTheme.colorScheme.onPrimary
                            else MaterialTheme.colorScheme.onSurface)
            }
        }
    }
}

@Composable
private fun BoardTrack(app: RealitaApp, locale: AppLocale,
                       board: List<id.realita62.lifeboard.engine.Tile>,
                       positions: List<Int>) {
    Surface(modifier = Modifier.fillMaxWidth().height(120.dp),
        color = MaterialTheme.colorScheme.surface, tonalElevation = 2.dp) {
        LazyColumn(modifier = Modifier.padding(6.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)) {
            items(board.take(60).chunked(10)) { row ->
                Row(modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    row.forEach { tile ->
                        Box(modifier = Modifier.size(28.dp).clip(CircleShape)
                            .background(colorForTile(tile.type)),
                            contentAlignment = Alignment.Center) {
                            val isCurrent = positions.any { it == tile.index }
                            if (isCurrent) {
                                Box(modifier = Modifier.size(10.dp).clip(CircleShape)
                                    .background(MaterialTheme.colorScheme.primary))
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun colorForTile(t: id.realita62.lifeboard.engine.TileType): Color = when (t) {
    id.realita62.lifeboard.engine.TileType.PAYDAY -> Color(0xFF4CAF50)
    id.realita62.lifeboard.engine.TileType.EVENT -> Color(0xFFFFC107)
    id.realita62.lifeboard.engine.TileType.LUCK -> Color(0xFF2196F3)
    id.realita62.lifeboard.engine.TileType.MARRIAGE -> Color(0xFFE91E63)
    id.realita62.lifeboard.engine.TileType.CHILD -> Color(0xFF9C27B0)
    id.realita62.lifeboard.engine.TileType.ASSET_SHOP -> Color(0xFF795548)
    id.realita62.lifeboard.engine.TileType.MAHAR_PARTAI_GATE -> Color(0xFF607D8B)
    id.realita62.lifeboard.engine.TileType.TENDER -> Color(0xFFFF9800)
    id.realita62.lifeboard.engine.TileType.RETIREMENT_FORK -> Color(0xFFB31919)
    id.realita62.lifeboard.engine.TileType.START -> Color(0xFFD4A23A)
    id.realita62.lifeboard.engine.TileType.EDUCATION_FORK -> Color(0xFFD4A23A)
    id.realita62.lifeboard.engine.TileType.BLANK -> Color(0xFFE0E0E0)
}

private fun happinessIconAndTint(h: Int): Pair<androidx.compose.ui.graphics.vector.ImageVector, Color> {
    return when {
        h >= 10 -> Icons.Default.SentimentVerySatisfied to Color(0xFF1E7D5C)
        h > 0 -> Icons.Default.SentimentNeutral to Color(0xFF888888)
        h == 0 -> Icons.Default.SentimentNeutral to Color(0xFF888888)
        h > -10 -> Icons.Default.SentimentDissatisfied to Color(0xFFFFA000)
        else -> Icons.Default.SentimentVeryDissatisfied to Color(0xFFD32F2F)
    }
}

private fun careerLabel(c: Career, locale: AppLocale): String =
    if (locale == AppLocale.INDONESIAN) c.labelId else c.labelEn

private fun formatEvent(e: GameEvent, locale: AppLocale, app: RealitaApp): String = when (e) {
    is GameEvent.Payday -> if (locale == AppLocale.INDONESIAN) "Gaji ${e.amount}M (Tapera ${e.tapera}M)" else "Payday ${e.amount}M (TAPERA ${e.tapera}M)"
    is GameEvent.PaydaySkipped -> if (locale == AppLocale.INDONESIAN) "Gaji dilangkahi (PHK)" else "Payday skipped (layoff)"
    is GameEvent.LivingCost -> if (locale == AppLocale.INDONESIAN) "Biaya hidup -${e.amount}M" else "Living cost -${e.amount}M"
    is GameEvent.UktInterest -> "UKT +${e.amount}M"
    is GameEvent.KprInterest -> "KPR +${e.amount}M (${e.assetId})"
    is GameEvent.PinjolInterest -> "Pinjol +${e.amount}M"
    is GameEvent.SideBusinessPaid -> if (locale == AppLocale.INDONESIAN) "Usaha sampingan +${e.amount}M" else "Side business +${e.amount}M"
    is GameEvent.SideBusinessEnded -> if (locale == AppLocale.INDONESIAN) "Usaha sampingan berakhir" else "Side business ended"
    is GameEvent.FuelSubsidyEnded -> if (locale == AppLocale.INDONESIAN) "Subsidi BBM pulih" else "Fuel subsidy recovered"
    is GameEvent.LandlordRentEnded -> if (locale == AppLocale.INDONESIAN) "Sewa stabil" else "Rent stabilized"
    is GameEvent.CheapRentEnded -> if (locale == AppLocale.INDONESIAN) "Promo sewa berakhir" else "Cheap rent ended"
    is GameEvent.StoleProjectFunds -> if (locale == AppLocale.INDONESIAN) "Curi dana +${e.amount}M (Heat ${e.newHeat})" else "Stole funds +${e.amount}M (Heat ${e.newHeat})"
    is GameEvent.KpkStingMiss -> if (locale == AppLocale.INDONESIAN) "KPK lepas" else "KPK missed"
    is GameEvent.KpkStingCaught -> if (locale == AppLocale.INDONESIAN) "OTT KPK! Tunai -${e.cashLost}M" else "KPK OTT! Cash -${e.cashLost}M"
    is GameEvent.Married -> if (locale == AppLocale.INDONESIAN) "Menikah (${if (e.lavish) "Mewah" else "Sederhana"})" else "Married (${if (e.lavish) "Lavish" else "Modest"})"
    is GameEvent.ChildBorn -> if (locale == AppLocale.INDONESIAN) "Anak lahir" else "Child born"
    is GameEvent.SchoolFunded -> if (locale == AppLocale.INDONESIAN) "Sekolah ${if (e.private) "swasta" else "negeri"} -${e.cost}M" else "School ${if (e.private) "private" else "public"} -${e.cost}M"
    is GameEvent.EnteredPoliticianPath -> if (locale == AppLocale.INDONESIAN) "Masuk politik (${if (e.corrupt) "Korupsi" else "Bersih"}) -${e.dowry}M" else "Politics (${if (e.corrupt) "Corrupt" else "Clean"}) -${e.dowry}M"
    is GameEvent.PoliticianEntryFailed -> if (locale == AppLocale.INDONESIAN) "Gagal masuk politik" else "Politics entry failed"
    is GameEvent.NepotismPerk -> if (locale == AppLocale.INDONESIAN) "Nepotisme +${e.gain}M" else "Nepotism +${e.gain}M"
    is GameEvent.Retired -> if (locale == AppLocale.INDONESIAN) "Pensiun (${e.choice.id}) skor ${e.score}M ${if (e.wargaTeladan) "★ Warga Teladan +62" else ""}" else "Retired (${e.choice.id}) score ${e.score}M ${if (e.wargaTeladan) "★ Model Citizen" else ""}"
    is GameEvent.CardDrawn -> if (locale == AppLocale.INDONESIAN) "Kad ${e.cardId}" else "Card ${e.cardId}"
    is GameEvent.CashDelta -> "${if (e.amount >= 0) "+" else ""}${e.amount}M — ${e.reason}"
    is GameEvent.HappinessDelta -> "H ${if (e.delta >= 0) "+" else ""}${e.delta} — ${e.reason}"
    is GameEvent.SkipTurn -> if (locale == AppLocale.INDONESIAN) "Langkah ${e.laps} giliran" else "Skip ${e.laps} turn(s)"
    is GameEvent.Moved -> if (locale == AppLocale.INDONESIAN) "${e.fromTile}→${e.toTile}" else "${e.fromTile}→${e.toTile}"
    is GameEvent.LapCompleted -> if (locale == AppLocale.INDONESIAN) "Putaran ${e.laps}" else "Lap ${e.laps}"
    is GameEvent.AssetPurchased -> if (locale == AppLocale.INDONESIAN) "Beli ${e.name}" else "Bought ${e.name}"
    is GameEvent.TokenAwarded -> if (locale == AppLocale.INDONESIAN) "Token: ${e.token}" else "Token: ${e.token}"
    is GameEvent.LoanTaken -> if (locale == AppLocale.INDONESIAN) "Pinjaman ${e.principal}M @${(e.interestPct * 100).toInt()}%/lap" else "Loan ${e.principal}M @${(e.interestPct * 100).toInt()}%/lap"
    is GameEvent.DebtFlagged -> "⚠ ${e.flag}"
    GameEvent.Empty -> ""
}

@Composable
private fun BottomActionBar(app: RealitaApp, locale: AppLocale,
                            vm: GameViewModel, orch: id.realita62.lifeboard.engine.GameOrchestrator) {
    val state = orch.state
    val currentPlayer = state.players[state.currentPlayerIdx]
    val scope = rememberCoroutineScope()
    Row(modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        if (currentPlayer.education == null) {
            // Show education path buttons
            Button(onClick = { vm.setEducationPath(state.currentPlayerIdx, EducationPath.COLLEGE) },
                modifier = Modifier.weight(1f).height(56.dp)) {
                Text(if (locale == AppLocale.INDONESIAN) "PTN (Kuliah)" else "College (PTN)")
            }
            Button(onClick = { vm.setEducationPath(state.currentPlayerIdx, EducationPath.SMA_SMK) },
                modifier = Modifier.weight(1f).height(56.dp)) {
                Text(if (locale == AppLocale.INDONESIAN) "SMA/SMK" else "SMA/SMK")
            }
        } else if (currentPlayer.career == null) {
            // Show career picker (simplified — pick from defaults based on education)
            CareerPicker(app, locale, education = currentPlayer.education!!,
                onPick = { c -> vm.assignCareer(state.currentPlayerIdx, c) })
        } else {
            Button(
                onClick = {
                    scope.launch {
                        val result = vm.tick()
                        // Autosave
                        app.settings.saveGame(orch.serialize())
                    }
                },
                modifier = Modifier.weight(1f).height(56.dp)
            ) {
                Icon(Icons.Default.Casino, contentDescription = null)
                Spacer(Modifier.width(8.dp))
                Text(if (locale == AppLocale.INDONESIAN) "Lempar Dadu" else "Roll Dice")
            }
        }
    }
}

@Composable
private fun CareerPicker(app: RealitaApp, locale: AppLocale,
                         education: EducationPath,
                         onPick: (Career) -> Unit) {
    val options = when (education) {
        EducationPath.COLLEGE -> listOf(Career.SCBD_EMPLOYEE, Career.PNS, Career.CONTRACTOR)
        EducationPath.SMA_SMK -> listOf(Career.OJOL_DRIVER, Career.DAILY_WORKER)
    }
    Row(modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        options.forEach { c ->
            Button(onClick = { onPick(c) },
                modifier = Modifier.weight(1f).height(56.dp)) {
                Text(careerLabel(c, locale), fontSize = 12.sp)
            }
        }
    }
}

// ---------------------------------------------------------------------
// DIALOGS
// ---------------------------------------------------------------------

@Composable
private fun ChoiceCardDialog(app: RealitaApp, locale: AppLocale,
                             titleEn: String, titleId: String,
                             flavorEn: String, flavorId: String,
                             choices: List<Pair<String, String>>,
                             onChoose: (String) -> Unit) {
    AlertDialog(
        onDismissRequest = { /* must choose */ },
        title = { Text(if (locale == AppLocale.INDONESIAN) titleId else titleEn) },
        text = {
            Column {
                Text(if (locale == AppLocale.INDONESIAN) flavorId else flavorEn,
                    style = MaterialTheme.typography.bodyMedium)
                Spacer(Modifier.height(12.dp))
                choices.forEach { (label, code) ->
                    Button(onClick = { onChoose(code) },
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                        Text(label)
                    }
                }
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun MarriageDialog(app: RealitaApp, locale: AppLocale, onPick: (Boolean) -> Unit) {
    AlertDialog(
        onDismissRequest = { /* must choose */ },
        title = { Text(if (locale == AppLocale.INDONESIAN) "Menaiki Pelaminan" else "Marriage") },
        text = {
            Column {
                Button(onClick = { onPick(false) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "KUA Sederhana (Rp 1M, +8H)" else "Modest KUA (Rp 1M, +8H)")
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(true) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Pesta Mewah (Rp 8M, +25H)" else "Lavish (Rp 8M, +25H)")
                }
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun AssetShopDialog(app: RealitaApp, locale: AppLocale,
                            catalogue: id.realita62.lifeboard.engine.AssetCatalogue,
                            onBuy: (String) -> Unit) {
    AlertDialog(
        onDismissRequest = { /* must choose or skip */ },
        title = { Text(if (locale == AppLocale.INDONESIAN) "Toko Aset" else "Asset Shop") },
        text = {
            Column {
                catalogue.items.forEach { a ->
                    Button(onClick = { onBuy(a.id) },
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                        Text(
                            "${if (locale == AppLocale.INDONESIAN) a.nameId else a.nameEn} — Rp ${a.price}M",
                            fontSize = 12.sp
                        )
                    }
                }
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun MaharPartaiDialog(app: RealitaApp, locale: AppLocale,
                              onPick: (enter: Boolean, corrupt: Boolean) -> Unit) {
    AlertDialog(
        onDismissRequest = { onPick(false, false) },
        title = { Text(if (locale == AppLocale.INDONESIAN) "Mahar Partai" else "Party Dowry") },
        text = {
            Column {
                Text(if (locale == AppLocale.INDONESIAN)
                    "Bayar Rp 15M untuk masuk politik. Pilih jalur:"
                    else "Pay Rp 15M to enter politics. Choose route:")
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(true, false) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Bersih (+H, risiko rendah)" else "Clean (+H, low risk)")
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(true, true) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Korupsi (+cepat, risiko KPK)" else "Corrupt (fast cash, KPK risk)")
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(false, false) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Tolak" else "Decline")
                }
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun RetirementDialog(app: RealitaApp, locale: AppLocale,
                             onPick: (RetirementChoice) -> Unit) {
    AlertDialog(
        onDismissRequest = { /* must choose */ },
        title = { Text(if (locale == AppLocale.INDONESIAN) "Pilih Pensiun" else "Choose Retirement") },
        text = {
            Column {
                Button(onClick = { onPick(RetirementChoice.KAMPUNG_JOGJA) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Kampung Jogja" else "Kampung Jogja")
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(RetirementChoice.ISLAND_BALI) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Pulau Bali" else "Island Bali")
                }
                Spacer(Modifier.height(8.dp))
                Button(onClick = { onPick(RetirementChoice.ELITE_MENTENG) }, modifier = Modifier.fillMaxWidth()) {
                    Text(if (locale == AppLocale.INDONESIAN) "Menteng Elite" else "Elite Menteng")
                }
            }
        },
        confirmButton = {}
    )
}

@Composable
private fun GameOverDialog(app: RealitaApp, locale: AppLocale,
                           orch: id.realita62.lifeboard.engine.GameOrchestrator,
                           onReplay: () -> Unit) {
    val ranked = orch.state.players
        .map { it to orch.engine.finalScore(it) }
        .sortedByDescending { it.second }
    AlertDialog(
        onDismissRequest = { /* must choose */ },
        title = { Text(if (locale == AppLocale.INDONESIAN) "Permainan Tamat" else "Game Over") },
        text = {
            Column {
                ranked.forEachIndexed { i, (p, score) ->
                    val wargaTeladan = orch.engine.isWargaTeladan(p)
                    Text(
                        "${i + 1}. ${p.name} — ${score}M" +
                        if (wargaTeladan) " ★ ${if (locale == AppLocale.INDONESIAN) "Warga Teladan +62" else "Model Citizen"}" else "",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        },
        confirmButton = {
            Button(onClick = onReplay) {
                Text(if (locale == AppLocale.INDONESIAN) "Main Lagi" else "Play Again")
            }
        }
    )
}

private fun choiceLabel(app: RealitaApp, locale: AppLocale, effect: String, choice: String): String {
    return when (effect) {
        "EVENT_MBG_TENDER" -> when (choice) {
            "skim" -> if (locale == AppLocale.INDONESIAN) "Skim (+Rp 8M, risiko)" else "Skim (+Rp 8M, risk)"
            else -> if (locale == AppLocale.INDONESIAN) "Tolak (+5H)" else "Decline (+5H)"
        }
        "EVENT_PARTY_DOWRY_OFFER" -> when (choice) {
            "clean" -> if (locale == AppLocale.INDONESIAN) "Masuk Bersih" else "Enter Clean"
            "corrupt" -> if (locale == AppLocale.INDONESIAN) "Masuk Korupsi" else "Enter Corrupt"
            else -> if (locale == AppLocale.INDONESIAN) "Tolak" else "Decline"
        }
        "EVENT_PORK_BARREL" -> when (choice) {
            "corrupt" -> if (locale == AppLocale.INDONESIAN) "Korupsi (+Rp 10M, +Heat)" else "Corrupt (+Rp 10M, +Heat)"
            else -> if (locale == AppLocale.INDONESIAN) "Bersih (+4H)" else "Clean (+4H)"
        }
        "EVENT_PRIVATE_SCHOOL_FEE" -> when (choice) {
            "private" -> if (locale == AppLocale.INDONESIAN) "Swasta (-Rp 5M)" else "Private (-Rp 5M)"
            else -> if (locale == AppLocale.INDONESIAN) "Negeri (-3H)" else "Public (-3H)"
        }
        "EVENT_RELATIVE_NEEDS_HELP" -> when (choice) {
            "help" -> if (locale == AppLocale.INDONESIAN) "Bantu (-Rp 2M, +4H)" else "Help (-Rp 2M, +4H)"
            else -> if (locale == AppLocale.INDONESIAN) "Tolak (-4H)" else "Refuse (-4H)"
        }
        "EVENT_GAMBLING_AD" -> when (choice) {
            "join" -> if (locale == AppLocale.INDONESIAN) "Ikut (-Rp 3M, -5H)" else "Join (-Rp 3M, -5H)"
            else -> if (locale == AppLocale.INDONESIAN) "Abaikan (+2H)" else "Ignore (+2H)"
        }
        "EVENT_SIDE_BUSINESS" -> when (choice) {
            "start" -> if (locale == AppLocale.INDONESIAN) "Mulai (-Rp 3M)" else "Start (-Rp 3M)"
            else -> if (locale == AppLocale.INDONESIAN) "Lewati" else "Skip"
        }
        "EVENT_BRIBE_OFFER" -> when (choice) {
            "accept" -> if (locale == AppLocale.INDONESIAN) "Terima (+Rp 4M, -5H)" else "Accept (+Rp 4M, -5H)"
            else -> if (locale == AppLocale.INDONESIAN) "Tolak (+3H)" else "Decline (+3H)"
        }
        "EVENT_VOTER_HANDOUT" -> when (choice) {
            "accept" -> if (locale == AppLocale.INDONESIAN) "Terima (+Rp 0.5M, -3H)" else "Accept (+Rp 0.5M, -3H)"
            else -> if (locale == AppLocale.INDONESIAN) "Tolak (+3H)" else "Refuse (+3H)"
        }
        else -> choice
    }
}
