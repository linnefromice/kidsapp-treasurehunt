import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/pen/pen_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

/// すべての解放フラグを立てた初期状態（解放ゲートを無効化したいテスト向け）。
const _allStylesUnlocked = {
  'settings.trailUnlock.rainbow3': true,
  'settings.trailUnlock.rainbowFull': true,
};

Future<ProviderContainer> _pumpPen(
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
      child: const MaterialApp(home: PenScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('renders a chip for every trail style', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpPen(tester, prefs);

    for (final style in TrailStyle.values) {
      expect(find.byKey(ValueKey('trailStyle.${style.id}')), findsOneWidget);
    }
  });

  testWidgets('solid is the default and shows a chip for every colour', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    expect(
      container.read(trailSettingControllerProvider).style,
      TrailStyle.solid,
    );
    for (final choice in TrailColorChoice.values) {
      expect(find.byKey(ValueKey('trailColor.${choice.id}')), findsOneWidget);
    }
    // 単色時はにじ3色のドロップダウンは出ない。
    expect(find.byKey(const ValueKey('trail3.slot0')), findsNothing);
  });

  testWidgets('selecting a solid colour persists and reflects', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    expect(
      container.read(trailSettingControllerProvider).solidColor,
      TrailColorChoice.sky,
    );

    await tester.tap(find.byKey(const ValueKey('trailColor.pink')));
    await tester.pump();

    expect(
      container.read(trailSettingControllerProvider).solidColor,
      TrailColorChoice.pink,
    );
    expect(prefs.getString('settings.trailColor'), 'pink');
  });

  testWidgets('selecting rainbow3 reveals three dropdowns and persists style', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({..._allStylesUnlocked});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbow3')));
    await tester.pump();

    expect(
      container.read(trailSettingControllerProvider).style,
      TrailStyle.rainbow3,
    );
    expect(prefs.getString('settings.trailStyle'), 'rainbow3');
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey('trail3.slot$i')), findsOneWidget);
    }
    // 単色チップは隠れる。
    expect(find.byKey(const ValueKey('trailColor.sky')), findsNothing);
  });

  testWidgets('selecting rainbowFull hides the dropdowns', (tester) async {
    SharedPreferences.setMockInitialValues({..._allStylesUnlocked});
    final prefs = await SharedPreferences.getInstance();
    await _pumpPen(tester, prefs);

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbow3')));
    await tester.pump();
    expect(find.byKey(const ValueKey('trail3.slot0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbowFull')));
    await tester.pump();
    expect(find.byKey(const ValueKey('trail3.slot0')), findsNothing);
  });

  testWidgets('changing a rainbow3 dropdown persists the csv and reflects', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({..._allStylesUnlocked});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbow3')));
    await tester.pump();

    // 既定の 3 色は sky,pink,yellow。1 つめ(slot0)を むらさき に変える。
    await tester.tap(find.byKey(const ValueKey('trail3.slot0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('むらさき').last);
    await tester.pumpAndSettle();

    expect(
      container.read(trailSettingControllerProvider).threeColors.first,
      TrailColorChoice.purple,
    );
    expect(prefs.getString('settings.trailColors3'), 'purple,pink,yellow');
  });

  testWidgets('locked styles show a lock and an unlock hint by default', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpPen(tester, prefs);

    // ロック中スタイルのチップには🔒（lock_outline）が出る。
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    // 各ロックスタイルのやさしいヒント行が出る。
    expect(
      find.byKey(const ValueKey('trailStyleLockedHint.rainbow3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trailStyleLockedHint.rainbowFull')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a locked style does not change the selected style', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbowFull')));
    await tester.pump();

    // onSelected:null なので無反応。solid のまま。
    expect(
      container.read(trailSettingControllerProvider).style,
      TrailStyle.solid,
    );
    expect(find.byKey(const ValueKey('trail3.slot0')), findsNothing);
  });

  testWidgets('an unlocked style is selectable and shows no hint for it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings.trailUnlock.rainbow3': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = await _pumpPen(tester, prefs);

    // rainbow3 は解放済み → ヒント無し、rainbowFull はまだロック → ヒント有り。
    expect(
      find.byKey(const ValueKey('trailStyleLockedHint.rainbow3')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('trailStyleLockedHint.rainbowFull')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('trailStyle.rainbow3')));
    await tester.pump();
    expect(
      container.read(trailSettingControllerProvider).style,
      TrailStyle.rainbow3,
    );
    expect(find.byKey(const ValueKey('trail3.slot0')), findsOneWidget);
  });
}
