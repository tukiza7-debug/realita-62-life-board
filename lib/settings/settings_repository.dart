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

  final SharedPreferences _prefs;
  SettingsRepository(this._prefs);

  AppSettings load() {
    final savedVersion = _prefs.getInt(_schemaVersion) ?? 1;
    // Future migrations go here: if (savedVersion < 2) migrateV1toV2();
    return AppSettings(
      locale: _prefs.getString(_locale) == null
          ? AppLocale.system
          : AppLocale.values.firstWhere(
              (e) => e.name == _prefs.getString(_locale),
              orElse: () => AppLocale.system),
      themeMode: AppThemeMode.values.firstWhere(
          (e) => e.name == (_prefs.getString(_themeMode) ?? 'system'),
          orElse: () => AppThemeMode.system),
      highContrast: _prefs.getBool(_highContrast) ?? false,
      colorblindSafeTiles: _prefs.getBool(_colorblindSafe) ?? true,
      orientation: OrientationMode.values.firstWhere(
          (e) => e.name == (_prefs.getString(_orientation) ?? 'auto'),
          orElse: () => OrientationMode.auto),
      keepScreenOn: _prefs.getBool(_keepScreenOn) ?? true,
      masterVolume: _prefs.getDouble(_masterVolume) ?? 0.8,
      musicVolume: _prefs.getDouble(_musicVolume) ?? 0.6,
      sfxVolume: _prefs.getDouble(_sfxVolume) ?? 0.8,
      muteAll: _prefs.getBool(_muteAll) ?? false,
      hapticsEnabled: _prefs.getBool(_hapticsEnabled) ?? true,
      hapticIntensity: HapticIntensity.values.firstWhere(
          (e) => e.name == (_prefs.getString(_hapticIntensity) ?? 'normal'),
          orElse: () => HapticIntensity.normal),
      motionLevel: MotionLevel.values.firstWhere(
          (e) => e.name == (_prefs.getString(_motionLevel) ?? 'full'),
          orElse: () => MotionLevel.full),
      gameSpeed: GameSpeed.values.firstWhere(
          (e) => e.name == (_prefs.getString(_gameSpeed) ?? 'normal'),
          orElse: () => GameSpeed.normal),
      aiSpeed: GameSpeed.values.firstWhere(
          (e) => e.name == (_prefs.getString(_aiSpeed) ?? 'normal'),
          orElse: () => GameSpeed.normal),
      skipOwnTurns: _prefs.getBool(_skipOwnTurns) ?? false,
      confirmPurchases: _prefs.getBool(_confirmPurchases) ?? true,
      showTileHints: _prefs.getBool(_showTileHints) ?? true,
      showScoreEstimate: _prefs.getBool(_showScoreEstimate) ?? true,
      screenReaderAnnouncements: _prefs.getBool(_screenReader) ?? true,
      largerTouchTargets: _prefs.getBool(_largerTouch) ?? false,
      schemaVersion: savedVersion,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_locale, s.locale.name);
    await _prefs.setString(_themeMode, s.themeMode.name);
    await _prefs.setBool(_highContrast, s.highContrast);
    await _prefs.setBool(_colorblindSafe, s.colorblindSafeTiles);
    await _prefs.setString(_orientation, s.orientation.name);
    await _prefs.setBool(_keepScreenOn, s.keepScreenOn);
    await _prefs.setDouble(_masterVolume, s.masterVolume);
    await _prefs.setDouble(_musicVolume, s.musicVolume);
    await _prefs.setDouble(_sfxVolume, s.sfxVolume);
    await _prefs.setBool(_muteAll, s.muteAll);
    await _prefs.setBool(_hapticsEnabled, s.hapticsEnabled);
    await _prefs.setString(_hapticIntensity, s.hapticIntensity.name);
    await _prefs.setString(_motionLevel, s.motionLevel.name);
    await _prefs.setString(_gameSpeed, s.gameSpeed.name);
    await _prefs.setString(_aiSpeed, s.aiSpeed.name);
    await _prefs.setBool(_skipOwnTurns, s.skipOwnTurns);
    await _prefs.setBool(_confirmPurchases, s.confirmPurchases);
    await _prefs.setBool(_showTileHints, s.showTileHints);
    await _prefs.setBool(_showScoreEstimate, s.showScoreEstimate);
    await _prefs.setBool(_screenReader, s.screenReaderAnnouncements);
    await _prefs.setBool(_largerTouch, s.largerTouchTargets);
    await _prefs.setInt(_schemaVersion, _kSchemaVersion);
  }

  Future<void> resetToDefaults() async {
    await _prefs.clear();
  }
}
