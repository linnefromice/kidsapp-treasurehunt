import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

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
  testWidgets('empty slots are blank (no avatar) with a placeholder', (
    tester,
  ) async {
    await _pumpApp(tester, {});

    // 未作成スロットは固定アバターを出さず、白紙プレースホルダを表示する。
    expect(find.byKey(const ValueKey('slot-empty.slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-avatar.slot1')), findsNothing);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });

  testWidgets(
    'tapping a new slot lets you pick an emoji, then enters the map',
    (tester) async {
      final c = await _pumpApp(tester, {});

      // 白紙スロットをタップ -> 絵文字ピッカーが開く。
      await tester.tap(find.byKey(const ValueKey('slot-card.slot1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('emoji-picker')), findsOneWidget);

      // 絵文字を選ぶ -> スロット作成 + 地図へ。
      await tester.tap(find.byKey(const ValueKey('emoji-pick.🦊')));
      // Use pump() instead of pumpAndSettle(): TreasureMapScreen has a
      // repeating pulse animation that never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = c.read(saveSlotControllerProvider);
      expect(state.containsKey('slot1'), isTrue);
      expect(state['slot1'], '🦊');
      expect(find.text('たからの ちず'), findsOneWidget); // 宝の地図ホーム
    },
  );

  testWidgets('a created slot shows its chosen emoji avatar', (tester) async {
    await _pumpApp(tester, {
      'save.createdSlotIds': ['slot2'],
      'save.avatar.slot2': '🐼',
      'progress.slot2.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('slot-avatar.slot2')), findsOneWidget);
    expect(find.text('🐼'), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-empty.slot2')), findsNothing);
  });

  testWidgets('canceling the emoji picker keeps the slot uncreated', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {});

    await tester.tap(find.byKey(const ValueKey('slot-card.slot1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('emoji-picker')), findsOneWidget);

    // 戻るボタンで閉じる -> スロットは未作成のまま白紙が維持される。
    await tester.tap(find.byKey(const ValueKey('emoji-cancel')));
    await tester.pumpAndSettle();

    expect(c.read(saveSlotControllerProvider).containsKey('slot1'), isFalse);
    expect(find.byKey(const ValueKey('slot-empty.slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });

  testWidgets('reset requires parental gate and uncreates the slot', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {
      'save.createdSlotIds': ['slot1'],
      'save.avatar.slot1': '🐶',
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('slot-continue.slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-avatar.slot1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('slot-reset.slot1')));
    await tester.pumpAndSettle(); // 保護者ゲートのダイアログ表示
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(c.read(saveSlotControllerProvider).containsKey('slot1'), isFalse);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
    // アバターは消え、白紙プレースホルダへ戻る。
    expect(find.byKey(const ValueKey('slot-avatar.slot1')), findsNothing);
    expect(find.byKey(const ValueKey('slot-empty.slot1')), findsOneWidget);
  });

  testWidgets('a created slot can change its avatar without a parental gate', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {
      'save.createdSlotIds': ['slot1'],
      'save.avatar.slot1': '🐶',
      'progress.slot1.unlockedSceneIds': ['scene01'],
      'progress.slot1.clearedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('slot-edit.slot1')), findsOneWidget);

    // 編集ボタン -> ピッカー（保護者ゲートは挟まない）。
    await tester.tap(find.byKey(const ValueKey('slot-edit.slot1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('emoji-picker')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('emoji-pick.🦊')));
    await tester.pumpAndSettle();

    // アバターが差し替わり、作成済み（つづき）状態と進捗は維持される。
    expect(c.read(saveSlotControllerProvider)['slot1'], '🦊');
    expect(find.byKey(const ValueKey('slot-continue.slot1')), findsOneWidget);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('progress.slot1.clearedSceneIds'), ['scene01']);
  });

  testWidgets('canceling the edit picker keeps the existing avatar', (
    tester,
  ) async {
    final c = await _pumpApp(tester, {
      'save.createdSlotIds': ['slot1'],
      'save.avatar.slot1': '🐶',
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    await tester.tap(find.byKey(const ValueKey('slot-edit.slot1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('emoji-cancel')));
    await tester.pumpAndSettle();

    // 戻る -> アバターは変わらず、作成済み状態も維持。
    expect(c.read(saveSlotControllerProvider)['slot1'], '🐶');
    expect(find.byKey(const ValueKey('slot-continue.slot1')), findsOneWidget);
  });

  testWidgets('an empty slot has no edit (change avatar) button', (
    tester,
  ) async {
    await _pumpApp(tester, {});

    expect(find.byKey(const ValueKey('slot-edit.slot1')), findsNothing);
  });

  testWidgets('free mode card is shown on the slot select screen', (
    tester,
  ) async {
    await _pumpApp(tester, {});

    expect(find.byKey(const ValueKey('slot-card.free')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-free')), findsOneWidget);
    expect(find.text('フリーモード'), findsOneWidget);
  });

  testWidgets('tapping free mode enters the map with every scene unlocked', (
    tester,
  ) async {
    await _pumpApp(tester, {});

    await tester.tap(find.byKey(const ValueKey('slot-card.free')));
    // Use pump() instead of pumpAndSettle(): TreasureMapScreen has a
    // repeating pulse animation that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('たからの ちず'), findsOneWidget); // 宝の地図ホーム
    // 全シーンが解放済み = ロック状態のノードが 1 つも無い。
    for (final entry in kSceneCatalog) {
      expect(
        find.byKey(ValueKey('node-locked.${entry.id}')),
        findsNothing,
        reason: '${entry.id} should not be locked in free mode',
      );
    }
  });
}
