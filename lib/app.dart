/// Root widget. Wires theme + locale + provider state.
///
/// SharedPreferences is loaded once in main() before runApp, so the build
/// method never has to call getInstance() (which would re-trigger a
/// FutureBuilder and could leave the app stuck on a spinner if the call
/// ever threw). Any error during prefs load falls back to default settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings/settings_repository.dart';
import 'theme/app_theme.dart';
import 'ui/recovery_screen.dart';
import 'ui/screens_router.dart';

class RealitaApp extends StatelessWidget {
  const RealitaApp({
    super.key,
    this.prefs,
    this.platformErrors = const [],
  });

  /// May be null when SharedPreferences.getInstance() threw in main().
  final SharedPreferences? prefs;

  /// Errors captured by runZonedGuarded / FlutterError.onError before the
  /// UI was ready. If non-empty, the app shows a recovery screen so a
  /// crash-loop cannot silently swallow the user.
  final List<FlutterErrorDetails> platformErrors;

  @override
  Widget build(BuildContext context) {
    if (platformErrors.isNotEmpty) {
      return MaterialApp(
        title: 'Realita +62',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        home: RecoveryScreen(errors: platformErrors),
      );
    }

    final repo = SettingsRepository(prefs);
    final settings = repo.load();
    return ChangeNotifierProvider(
      create: (_) => AppSettingsNotifier(repo, settings),
      child: Consumer<AppSettingsNotifier>(
        builder: (context, notifier, _) {
          final themeMode = _themeMode(notifier.settings.themeMode);
          return MaterialApp(
            title: 'Realita +62: Life Board',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('id'),
            ],
            locale: _resolveLocale(notifier.settings.locale),
            home: const ScreensRouter(),
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return RecoveryScreen(
                  errors: [...platformErrors, details],
                );
              };
              return child!;
            },
          );
        },
      ),
    );
  }

  ThemeMode _themeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Locale? _resolveLocale(AppLocale l) {
    switch (l) {
      case AppLocale.system:
        return null;
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.id:
        return const Locale('id');
    }
  }
}

class AppSettingsNotifier extends ChangeNotifier {
  AppSettings settings;
  final SettingsRepository _repo;
  AppSettingsNotifier(this._repo, this.settings);

  Future<void> update(AppSettings next) async {
    settings = next;
    await _repo.save(next);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await _repo.resetToDefaults();
    settings = _repo.load();
    notifyListeners();
  }
}
