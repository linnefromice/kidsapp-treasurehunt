import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('locale defaults to ja and updates + persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), const Locale('ja'));

    await container.read(localeControllerProvider.notifier).setLocale('en');
    expect(container.read(localeControllerProvider), const Locale('en'));
    expect(prefs.getString('settings.locale'), 'en');
  });
}
