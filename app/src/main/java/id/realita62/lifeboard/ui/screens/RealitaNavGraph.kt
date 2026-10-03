package id.realita62.lifeboard.ui.screens

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale
import id.realita62.lifeboard.ui.GameViewModel
import id.realita62.lifeboard.ui.GameViewModelFactory

@Composable
fun RealitaNavGraph(app: RealitaApp, locale: AppLocale) {
    val nav = rememberNavController()
    NavHost(navController = nav, startDestination = "menu") {
        composable("menu") { MainMenuScreen(app, locale, nav) }
        composable("new_game") { NewGameScreen(app, locale, nav) }
        composable("game") {
            val vm: GameViewModel = viewModel(factory = GameViewModelFactory(app))
            GameScreen(app, locale, nav, vm)
        }
        composable("tutorial") { TutorialScreen(app, locale, nav) }
        composable("glossary") { GlossaryScreen(app, locale, nav) }
        composable("settings") { SettingsScreen(app, locale, nav) }
    }
}
