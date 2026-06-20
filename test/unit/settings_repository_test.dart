import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to ja', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.localeCode(), 'ja');
  });

  test('persists locale code', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo.setLocaleCode('en');
    expect(repo.localeCode(), 'en');
  });

  test('defaults trail colour to sky', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.trailColorId(), 'sky');
  });

  test('persists trail colour id', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo.setTrailColorId('pink');
    expect(repo.trailColorId(), 'pink');
  });

  test('defaults trail style to solid', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.trailStyleId(), 'solid');
  });

  test('persists trail style id', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo.setTrailStyleId('rainbow3');
    expect(repo.trailStyleId(), 'rainbow3');
  });

  test('defaults trail three colours to sky,pink,yellow', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.trailColors3Csv(), 'sky,pink,yellow');
  });

  test('persists trail three colours csv', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo.setTrailColors3Csv('purple,orange,white');
    expect(repo.trailColors3Csv(), 'purple,orange,white');
  });
}
