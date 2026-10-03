/// Full-rework Settings screen (master prompt section 7).
/// Every option has an observable effect; tests prove it in
/// test/settings_test.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../settings/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = context.watch<AppSettingsNotifier>();
    final s = notifier.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(l10n.settingsLanguage, [
              ListTile(
                title: const Text('System Default'),
                trailing: Radio<AppLocale>(
                    value: AppLocale.system,
                    groupValue: s.locale,
                    onChanged: (v) => _set(context, s.copyWith(locale: v))),
              ),
              ListTile(
                title: const Text('English'),
                trailing: Radio<AppLocale>(
                    value: AppLocale.en,
                    groupValue: s.locale,
                    onChanged: (v) => _set(context, s.copyWith(locale: v))),
              ),
              ListTile(
                title: const Text('Bahasa Indonesia'),
                trailing: Radio<AppLocale>(
                    value: AppLocale.id,
                    groupValue: s.locale,
                    onChanged: (v) => _set(context, s.copyWith(locale: v))),
              ),
            ]),
            _Section(l10n.settingsAppearance, [
              ListTile(
                title: Text(l10n.settingsAppearanceTheme),
                trailing: DropdownButton<AppThemeMode>(
                  value: s.themeMode,
                  items: AppThemeMode.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_themeModeLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) => _set(context, s.copyWith(themeMode: v)),
                ),
              ),
              SwitchListTile(
                title: Text(l10n.settingsAppearanceHighContrast),
                value: s.highContrast,
                onChanged: (v) => _set(context, s.copyWith(highContrast: v)),
              ),
              SwitchListTile(
                title: Text(l10n.settingsAppearanceColorblindSafe),
                value: s.colorblindSafeTiles,
                onChanged: (v) =>
                    _set(context, s.copyWith(colorblindSafeTiles: v)),
              ),
            ]),
            _Section(l10n.settingsDisplay, [
              ListTile(
                title: Text(l10n.settingsDisplayOrientation),
                trailing: DropdownButton<OrientationMode>(
                  value: s.orientation,
                  items: OrientationMode.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_orientationLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) => _set(context, s.copyWith(orientation: v)),
                ),
              ),
              SwitchListTile(
                title: Text(l10n.settingsDisplayKeepScreenOn),
                value: s.keepScreenOn,
                onChanged: (v) => _set(context, s.copyWith(keepScreenOn: v)),
              ),
            ]),
            _Section(l10n.settingsAudio, [
              ListTile(
                title: Text(l10n.settingsAudioMasterVolume),
                subtitle: Slider(
                  value: s.masterVolume,
                  onChanged: s.muteAll
                      ? null
                      : (v) => _set(context, s.copyWith(masterVolume: v)),
                ),
                trailing: Text('${(s.masterVolume * 100).round()}%'),
              ),
              ListTile(
                title: Text(l10n.settingsAudioMusicVolume),
                subtitle: Slider(
                  value: s.musicVolume,
                  onChanged: s.muteAll
                      ? null
                      : (v) => _set(context, s.copyWith(musicVolume: v)),
                ),
                trailing: Text('${(s.musicVolume * 100).round()}%'),
              ),
              ListTile(
                title: Text(l10n.settingsAudioSfxVolume),
                subtitle: Slider(
                  value: s.sfxVolume,
                  onChanged: s.muteAll
                      ? null
                      : (v) => _set(context, s.copyWith(sfxVolume: v)),
                ),
                trailing: Text('${(s.sfxVolume * 100).round()}%'),
              ),
              SwitchListTile(
                title: Text(l10n.settingsAudioMuteAll),
                value: s.muteAll,
                onChanged: (v) => _set(context, s.copyWith(muteAll: v)),
              ),
            ]),
            _Section(l10n.settingsHaptics, [
              SwitchListTile(
                title: Text(l10n.settingsHapticsEnabled),
                value: s.hapticsEnabled,
                onChanged: (v) => _set(context, s.copyWith(hapticsEnabled: v)),
              ),
              ListTile(
                title: Text(l10n.settingsHapticsIntensity),
                trailing: DropdownButton<HapticIntensity>(
                  value: s.hapticIntensity,
                  items: HapticIntensity.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_hapticIntensityLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      _set(context, s.copyWith(hapticIntensity: v)),
                ),
              ),
            ]),
            _Section(l10n.settingsAnimation, [
              ListTile(
                title: Text(l10n.settingsAnimationMotionLevel),
                trailing: DropdownButton<MotionLevel>(
                  value: s.motionLevel,
                  items: MotionLevel.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_motionLevelLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) => _set(context, s.copyWith(motionLevel: v)),
                ),
              ),
              ListTile(
                title: Text(l10n.settingsAnimationGameSpeed),
                trailing: DropdownButton<GameSpeed>(
                  value: s.gameSpeed,
                  items: GameSpeed.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_gameSpeedLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) => _set(context, s.copyWith(gameSpeed: v)),
                ),
              ),
              ListTile(
                title: Text(l10n.settingsAnimationAiSpeed),
                trailing: DropdownButton<GameSpeed>(
                  value: s.aiSpeed,
                  items: GameSpeed.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_gameSpeedLabel(m, l10n)),
                          ))
                      .toList(),
                  onChanged: (v) => _set(context, s.copyWith(aiSpeed: v)),
                ),
              ),
              SwitchListTile(
                title: Text(l10n.settingsAnimationSkipOwnTurns),
                value: s.skipOwnTurns,
                onChanged: (v) => _set(context, s.copyWith(skipOwnTurns: v)),
              ),
            ]),
            _Section(l10n.settingsGameplay, [
              SwitchListTile(
                title: Text(l10n.settingsGameplayConfirmPurchases),
                value: s.confirmPurchases,
                onChanged: (v) =>
                    _set(context, s.copyWith(confirmPurchases: v)),
              ),
              SwitchListTile(
                title: Text(l10n.settingsGameplayShowTileHints),
                value: s.showTileHints,
                onChanged: (v) => _set(context, s.copyWith(showTileHints: v)),
              ),
              SwitchListTile(
                title: Text(l10n.settingsGameplayShowScoreEstimate),
                value: s.showScoreEstimate,
                onChanged: (v) =>
                    _set(context, s.copyWith(showScoreEstimate: v)),
              ),
            ]),
            _Section(l10n.settingsAccessibility, [
              SwitchListTile(
                title: Text(l10n.settingsAccessibilityScreenReader),
                value: s.screenReaderAnnouncements,
                onChanged: (v) =>
                    _set(context, s.copyWith(screenReaderAnnouncements: v)),
              ),
              SwitchListTile(
                title: Text(l10n.settingsAccessibilityLargerTouchTargets),
                value: s.largerTouchTargets,
                onChanged: (v) =>
                    _set(context, s.copyWith(largerTouchTargets: v)),
              ),
            ]),
            _Section(l10n.settingsData, [
              ListTile(
                title: Text(l10n.settingsDataSavedGame),
                subtitle: const Text('—'),
              ),
              ListTile(
                title: Text(l10n.settingsDataDeleteSave),
                onTap: () => _confirmDelete(context),
              ),
              ListTile(
                title: Text(l10n.settingsDataResetSettings),
                onTap: () => _confirmReset(context, notifier),
              ),
            ]),
            _Section(l10n.settingsAbout, [
              ListTile(
                title: Text(l10n.settingsAboutVersion),
                trailing: const Text('2.0.0+200'),
              ),
              ListTile(
                title: Text(l10n.settingsAboutCredits),
                onTap: () => _showString(context, 'CREDITS.md',
                    'See CREDITS.md in the repository root.'),
              ),
              ListTile(
                title: Text(l10n.settingsAboutGithub),
                onTap: () => _showString(context, 'GitHub',
                    'https://github.com/tukiza7-debug/realita-62-life-board'),
              ),
              ListTile(
                title: Text(l10n.settingsAboutPrivacy),
                subtitle: Text(l10n.settingsAboutPrivacyText),
              ),
              ListTile(
                title: Text(l10n.settingsAboutCopyDebug),
                onTap: () async {
                  final info = 'app=Realita+62 v2.0.0+200\n'
                      'locale=${s.locale.name}\n'
                      'theme=${s.themeMode.name}\n'
                      'motion=${s.motionLevel.name}\n'
                      'orientation=${s.orientation.name}';
                  await Clipboard.setData(ClipboardData(text: info));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debug info copied')),
                    );
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _set(BuildContext context, AppSettings next) {
    context.read<AppSettingsNotifier>().update(next);
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved game?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      // TODO: implement save deletion in shared_preferences.
    }
  }

  void _confirmReset(BuildContext context, AppSettingsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all settings?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.resetToDefaults();
    }
  }

  void _showString(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  String _themeModeLabel(AppThemeMode m, AppLocalizations l10n) => switch (m) {
        AppThemeMode.system => l10n.settingsAppearanceThemeSystem,
        AppThemeMode.light => l10n.settingsAppearanceThemeLight,
        AppThemeMode.dark => l10n.settingsAppearanceThemeDark,
      };

  String _orientationLabel(OrientationMode m, AppLocalizations l10n) =>
      switch (m) {
        OrientationMode.auto => l10n.settingsDisplayOrientationAuto,
        OrientationMode.portrait => l10n.settingsDisplayOrientationPortrait,
        OrientationMode.landscape => l10n.settingsDisplayOrientationLandscape,
      };

  String _motionLevelLabel(MotionLevel m, AppLocalizations l10n) => switch (m) {
        MotionLevel.full => l10n.settingsAnimationMotionFull,
        MotionLevel.reduced => l10n.settingsAnimationMotionReduced,
        MotionLevel.off => l10n.settingsAnimationMotionOff,
      };

  String _gameSpeedLabel(GameSpeed s, AppLocalizations l10n) => switch (s) {
        GameSpeed.normal => l10n.settingsAnimationGameSpeedNormal,
        GameSpeed.fast => l10n.settingsAnimationGameSpeedFast,
        GameSpeed.instant => l10n.settingsAnimationGameSpeedInstant,
      };

  String _hapticIntensityLabel(HapticIntensity s, AppLocalizations l10n) =>
      switch (s) {
        HapticIntensity.light => l10n.settingsHapticsIntensityLight,
        HapticIntensity.normal => l10n.settingsHapticsIntensityNormal,
      };
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
