import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/settings/settings_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<ProviderContainer> _pumpSettings(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('toggling to English persists locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpSettings(tester, prefs);

    await tester.tap(find.byKey(const ValueKey('lang.en')));
    await tester.pump();

    expect(container.read(localeControllerProvider).languageCode, 'en');
    expect(prefs.getString('settings.locale'), 'en');
  });

  testWidgets('settings no longer hosts the trail/pen customisation', (
    tester,
  ) async {
    // ペンのカスタマイズは /pen に分離した。設定にトレイル UI が残っていないこと。
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpSettings(tester, prefs);

    expect(find.byKey(const ValueKey('trailStyle.solid')), findsNothing);
    expect(find.byKey(const ValueKey('trailColor.sky')), findsNothing);
    expect(find.byKey(const ValueKey('trail-preview')), findsNothing);
  });
}
