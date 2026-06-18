import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  Map<String, Object> seed,
) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const TreasureHuntApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('tapping a new slot creates it and enters the map', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {});

    await tester.tap(find.byKey(const ValueKey('slot-card.slot1')));
    // Use pump() instead of pumpAndSettle(): TreasureMapScreen has a
    // repeating pulse animation that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isTrue);
    expect(find.text('たからの ちず'), findsOneWidget); // 宝の地図ホーム
  });

  testWidgets('reset requires parental gate and uncreates the slot', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {
      'save.createdSlotIds': ['slot1'],
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('slot-continue.slot1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('slot-reset.slot1')));
    await tester.pumpAndSettle(); // 保護者ゲートのダイアログ表示
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isFalse);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });
}
