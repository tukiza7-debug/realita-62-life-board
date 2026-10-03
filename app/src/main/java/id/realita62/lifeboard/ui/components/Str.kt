package id.realita62.lifeboard.ui.components

import id.realita62.lifeboard.RealitaApp
import id.realita62.lifeboard.l10n.AppLocale

/**
 * Simple string lookup — falls back to English if Indonesian is missing.
 * Real resource strings live in res/values-en/strings.xml and res/values-in/strings.xml.
 * This helper is used for UI strings that don't live in resource files (game-time
 * strings derived from data); static UI labels use R.string directly via LocalContext.
 */
fun Str(app: RealitaApp, locale: AppLocale, en: String, id: String): String =
    if (locale == AppLocale.INDONESIAN) id else en
