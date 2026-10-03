import 'package:flutter_test/flutter_test.dart';
import 'package:realita62_life_board/settings/settings_repository.dart';
import 'package:realita_engine/realita_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository.load corrupted values', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns defaults when prefs is empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final s = repo.load();
      expect(s.locale, AppLocale.system);
      expect(s.themeMode, AppThemeMode.system);
      expect(s.orientation, OrientationMode.auto);
      expect(s.masterVolume, 0.8);
      expect(s.motionLevel, MotionLevel.full);
      expect(s.schemaVersion, 1);
    });

    test('returns defaults when prefs is null', () {
      final repo = SettingsRepository(null);
      final s = repo.load();
      expect(s.locale, AppLocale.system);
      expect(s.themeMode, AppThemeMode.system);
      expect(s.orientation, OrientationMode.auto);
      expect(s.masterVolume, 0.8);
      expect(s.motionLevel, MotionLevel.full);
      expect(s.schemaVersion, 1);
    });

    test('falls back to default for unknown enum value', () async {
      SharedPreferences.setMockInitialValues({'motion_level': 'non_existent_value'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final s = repo.load();
      expect(s.motionLevel, MotionLevel.full);
    });

    test('falls back to default when a String is stored under a bool key', () async {
      // SharedPreferences only stores typed values via setBool/setString etc.
      // setString under a bool key persists as a String; our getter must
      // detect the type mismatch and fall back, not crash.
      SharedPreferences.setMockInitialValues({'mute_all': 'not_a_bool'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final s = repo.load();
      expect(s.muteAll, false);
    });

    test('falls back to default when a String is stored under a double key', () async {
      SharedPreferences.setMockInitialValues({'master_volume': 'not_a_double'});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final s = repo.load();
      expect(s.masterVolume, 0.8);
    });

    test('save() is a no-op when prefs is null', () async {
      final repo = SettingsRepository(null);
      await repo.save(const AppSettings());
      await repo.resetToDefaults();
    });

    test('round-trips a saved AppSettings', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      await repo.save(const AppSettings().copyWith(
        locale: AppLocale.id,
        themeMode: AppThemeMode.dark,
        masterVolume: 0.42,
        motionLevel: MotionLevel.off,
      ));
      final loaded = repo.load();
      expect(loaded.locale, AppLocale.id);
      expect(loaded.themeMode, AppThemeMode.dark);
      expect(loaded.masterVolume, 0.42);
      expect(loaded.motionLevel, MotionLevel.off);
    });
  });

  group('GameOrchestrator.deserialize corrupted saved_game', () {
    final lib = CardLibrary(events: const [], goodLuck: const [], badLuck: const []);

    test('throws FormatException for invalid JSON', () {
      expect(
        () => GameOrchestrator.deserialize(
            'not json', lib, BalanceConfig.defaultConfig),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on missing seed', () {
      const bad = '{"players": []}';
      expect(
        () => GameOrchestrator.deserialize(
            bad, lib, BalanceConfig.defaultConfig),
        throwsA(anything),
      );
    });
  });

  group('CardLibrary', () {
    test('empty arrays are accepted by fromJson', () {
      final lib = CardLibrary.fromJson(const {
        'events': <dynamic>[],
        'goodLuck': <dynamic>[],
        'badLuck': <dynamic>[],
      });
      expect(lib.events, isEmpty);
      expect(lib.goodLuck, isEmpty);
      expect(lib.badLuck, isEmpty);
    });

    test('findById returns null for unknown id', () {
      final lib = CardLibrary(events: const [], goodLuck: const [], badLuck: const []);
      expect(lib.findById('E99'), isNull);
    });
  });
}
