/// Typed settings repository — single source of truth for all app settings.
///
/// Per master-prompt section 7.1: every setting must have an observable
/// effect proven by a test. Defaults live in one place; migration on
/// upgrade is handled via [SettingsSchemaVersion].
library;

import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { system, en, id }

enum AppThemeMode { system, light, dark }

enum OrientationMode { auto, portrait, landscape }

enum MotionLevel { full, reduced, off }

enum GameSpeed { normal, fast, instant }

enum HapticIntensity { light, normal }

const _kSchemaVersion = 1;

class AppSettings {
  final AppLocale locale;
  final AppThemeMode themeMode;
  final bool highContrast;
  final bool colorblindSafeTiles;
  final OrientationMode orientation;
  final bool keepScreenOn;
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final bool muteAll;
  final bool hapticsEnabled;
  final HapticIntensity hapticIntensity;
  final MotionLevel motionLevel;
  final GameSpeed gameSpeed;
  final GameSpeed aiSpeed;
  final bool skipOwnTurns;
  final bool confirmPurchases;
  final bool showTileHints;
  final bool showScoreEstimate;
  final bool screenReaderAnnouncements;
  final bool largerTouchTargets;
  final int schemaVersion;

  const AppSettings({
    this.locale = AppLocale.system,
    this.themeMode = AppThemeMode.system,
    this.highContrast = false,
    this.colorblindSafeTiles = true,
    this.orientation = OrientationMode.auto,
    this.keepScreenOn = true,
    this.masterVolume = 0.8,
    this.musicVolume = 0.6,
    this.sfxVolume = 0.8,
    this.muteAll = false,
    this.hapticsEnabled = true,
    this.hapticIntensity = HapticIntensity.normal,
    this.motionLevel = MotionLevel.full,
    this.gameSpeed = GameSpeed.normal,
    this.aiSpeed = GameSpeed.normal,
    this.skipOwnTurns = false,
    this.confirmPurchases = true,
    this.showTileHints = true,
    this.showScoreEstimate = true,
    this.screenReaderAnnouncements = true,
    this.largerTouchTargets = false,
    this.schemaVersion = _kSchemaVersion,
  });

  AppSettings copyWith({
    AppLocale? locale,
    AppThemeMode? themeMode,
    bool? highContrast,
    bool? colorblindSafeTiles,
    OrientationMode? orientation,
    bool? keepScreenOn,
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    bool? muteAll,
    bool? hapticsEnabled,
    HapticIntensity? hapticIntensity,
    MotionLevel? motionLevel,
    GameSpeed? gameSpeed,
    GameSpeed? aiSpeed,
    bool? skipOwnTurns,
    bool? confirmPurchases,
    bool? showTileHints,
    bool? showScoreEstimate,
    bool? screenReaderAnnouncements,
    bool? largerTouchTargets,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        highContrast: highContrast ?? this.highContrast,
        colorblindSafeTiles: colorblindSafeTiles ?? this.colorblindSafeTiles,
        orientation: orientation ?? this.orientation,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        masterVolume: masterVolume ?? this.masterVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        muteAll: muteAll ?? this.muteAll,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        hapticIntensity: hapticIntensity ?? this.hapticIntensity,
        motionLevel: motionLevel ?? this.motionLevel,
        gameSpeed: gameSpeed ?? this.gameSpeed,
        aiSpeed: aiSpeed ?? this.aiSpeed,
        skipOwnTurns: skipOwnTurns ?? this.skipOwnTurns,
        confirmPurchases: confirmPurchases ?? this.confirmPurchases,
        showTileHints: showTileHints ?? this.showTileHints,
        showScoreEstimate: showScoreEstimate ?? this.showScoreEstimate,
        screenReaderAnnouncements:
            screenReaderAnnouncements ?? this.screenReaderAnnouncements,
        largerTouchTargets: largerTouchTargets ?? this.largerTouchTargets,
      );
}

class SettingsRepository {
  static const _locale = 'locale';
  static const _themeMode = 'theme_mode';
  static const _highContrast = 'high_contrast';
  static const _colorblindSafe = 'colorblind_safe';
  static const _orientation = 'orientation';
  static const _keepScreenOn = 'keep_screen_on';
  static const _masterVolume = 'master_volume';
  static const _musicVolume = 'music_volume';
  static const _sfxVolume = 'sfx_volume';
  static const _muteAll = 'mute_all';
  static const _hapticsEnabled = 'haptics_enabled';
  static const _hapticIntensity = 'haptic_intensity';
  static const _motionLevel = 'motion_level';
  static const _gameSpeed = 'game_speed';
  static const _aiSpeed = 'ai_speed';
  static const _skipOwnTurns = 'skip_own_turns';
  static const _confirmPurchases = 'confirm_purchases';
  static const _showTileHints = 'show_tile_hints';
  static const _showScoreEstimate = 'show_score_estimate';
  static const _screenReader = 'screen_reader';
  static const _largerTouch = 'larger_touch';
  static const _schemaVersion = 'schema_version';

  final SharedPreferences? _prefs;
  SettingsRepository(this._prefs);

  String? _getString(String key) {
    final p = _prefs;
    if (p == null) return null;
    try {
      final v = p.get(key);
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }

  bool? _getBool(String key) {
    final p = _prefs;
    if (p == null) return null;
    try {
      final v = p.get(key);
      return v is bool ? v : null;
    } catch (_) {
      return null;
    }
  }

  double? _getDouble(String key) {
    final p = _prefs;
    if (p == null) return null;
    try {
      final v = p.get(key);
      return v is double ? v : (v is int ? v.toDouble() : null);
    } catch (_) {
      return null;
    }
  }

  int? _getInt(String key) {
    final p = _prefs;
    if (p == null) return null;
    try {
      final v = p.get(key);
      return v is int ? v : (v is double ? v.toInt() : null);
    } catch (_) {
      return null;
    }
  }

  T _enum<T extends Enum>(String key, List<T> values, T def) {
    final name = _getString(key);
    if (name == null) return def;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return def;
  }

  AppSettings load() {
    final savedVersion = _getInt(_schemaVersion) ?? 1;
    return AppSettings(
      locale: _enum(_locale, AppLocale.values, AppLocale.system),
      themeMode: _enum(_themeMode, AppThemeMode.values, AppThemeMode.system),
      highContrast: _getBool(_highContrast) ?? false,
      colorblindSafeTiles: _getBool(_colorblindSafe) ?? true,
      orientation:
          _enum(_orientation, OrientationMode.values, OrientationMode.auto),
      keepScreenOn: _getBool(_keepScreenOn) ?? true,
      masterVolume: _getDouble(_masterVolume) ?? 0.8,
      musicVolume: _getDouble(_musicVolume) ?? 0.6,
      sfxVolume: _getDouble(_sfxVolume) ?? 0.8,
      muteAll: _getBool(_muteAll) ?? false,
      hapticsEnabled: _getBool(_hapticsEnabled) ?? true,
      hapticIntensity: _enum(
          _hapticIntensity, HapticIntensity.values, HapticIntensity.normal),
      motionLevel: _enum(_motionLevel, MotionLevel.values, MotionLevel.full),
      gameSpeed: _enum(_gameSpeed, GameSpeed.values, GameSpeed.normal),
      aiSpeed: _enum(_aiSpeed, GameSpeed.values, GameSpeed.normal),
      skipOwnTurns: _getBool(_skipOwnTurns) ?? false,
      confirmPurchases: _getBool(_confirmPurchases) ?? true,
      showTileHints: _getBool(_showTileHints) ?? true,
      showScoreEstimate: _getBool(_showScoreEstimate) ?? true,
      screenReaderAnnouncements: _getBool(_screenReader) ?? true,
      largerTouchTargets: _getBool(_largerTouch) ?? false,
      schemaVersion: savedVersion,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_locale, s.locale.name);
    await p.setString(_themeMode, s.themeMode.name);
    await p.setBool(_highContrast, s.highContrast);
    await p.setBool(_colorblindSafe, s.colorblindSafeTiles);
    await p.setString(_orientation, s.orientation.name);
    await p.setBool(_keepScreenOn, s.keepScreenOn);
    await p.setDouble(_masterVolume, s.masterVolume);
    await p.setDouble(_musicVolume, s.musicVolume);
    await p.setDouble(_sfxVolume, s.sfxVolume);
    await p.setBool(_muteAll, s.muteAll);
    await p.setBool(_hapticsEnabled, s.hapticsEnabled);
    await p.setString(_hapticIntensity, s.hapticIntensity.name);
    await p.setString(_motionLevel, s.motionLevel.name);
    await p.setString(_gameSpeed, s.gameSpeed.name);
    await p.setString(_aiSpeed, s.aiSpeed.name);
    await p.setBool(_skipOwnTurns, s.skipOwnTurns);
    await p.setBool(_confirmPurchases, s.confirmPurchases);
    await p.setBool(_showTileHints, s.showTileHints);
    await p.setBool(_showScoreEstimate, s.showScoreEstimate);
    await p.setBool(_screenReader, s.screenReaderAnnouncements);
    await p.setBool(_largerTouch, s.largerTouchTargets);
    await p.setInt(_schemaVersion, _kSchemaVersion);
  }

  Future<void> resetToDefaults() async {
    final p = _prefs;
    if (p == null) return;
    await p.clear();
  }
}
