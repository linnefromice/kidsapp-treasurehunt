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
}
