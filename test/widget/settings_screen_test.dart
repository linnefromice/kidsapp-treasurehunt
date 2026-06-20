import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
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

  testWidgets('renders a chip for every trail colour', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpSettings(tester, prefs);

    for (final choice in TrailColorChoice.values) {
      expect(find.byKey(ValueKey('trailColor.${choice.id}')), findsOneWidget);
    }
  });

  testWidgets('selecting a trail colour persists and reflects', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpSettings(tester, prefs);

    // 既定は sky。pink を選ぶと state と永続値の両方が pink になる。
    expect(container.read(trailColorControllerProvider), TrailColorChoice.sky);

    await tester.tap(find.byKey(const ValueKey('trailColor.pink')));
    await tester.pump();

    expect(container.read(trailColorControllerProvider), TrailColorChoice.pink);
    expect(prefs.getString('settings.trailColor'), 'pink');
  });
}
