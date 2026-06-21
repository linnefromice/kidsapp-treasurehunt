import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_screen.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

/// 図鑑画面のレンダリングだけを検証するため、カタログは同期の固定データで
/// 上書きする（実アセット読み込み＝スピナーで pumpAndSettle が止まるのを避ける。
/// 実カタログの読み込みは collectionCatalogProvider のテストで担保）。
const _fakeWorlds = [
  CollectionWorld(
    sceneId: 'scene01',
    titleKey: 'scene.scene01.title',
    iconIds: ['apple', 'duck', 'star'],
  ),
  CollectionWorld(
    sceneId: 'scene02',
    titleKey: 'scene.scene02.title',
    iconIds: ['ball', 'flower'],
  ),
];

Future<SharedPreferences> _pump(
  WidgetTester tester,
  List<String> discovered, {
  List<String> unseen = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'save.createdSlotIds': ['slot1'],
    'collection.slot1.discovered': discovered,
    'collection.slot1.unseen': unseen,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // 同期で返す → AsyncData 即時 → スピナー無しで pumpAndSettle が落ち着く。
      collectionCatalogProvider.overrideWith((ref) => _fakeWorlds),
    ],
  );
  addTearDown(container.dispose);
  container.read(activeSlotProvider.notifier).select('slot1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CollectionScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('discovered treasures are coloured, others are silhouettes', (
    tester,
  ) async {
    await _pump(tester, ['scene01:apple']);

    expect(
      find.byKey(const ValueKey('collection-found.scene01.apple')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-silhouette.scene01.duck')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-world.scene01')),
      findsOneWidget,
    );
  });

  testWidgets('a fresh collection shows everything as silhouettes', (
    tester,
  ) async {
    await _pump(tester, const []);

    expect(
      find.byKey(const ValueKey('collection-silhouette.scene01.apple')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collection-found.scene01.apple')),
      findsNothing,
    );
  });

  testWidgets('shows a NEW badge on unseen discoveries and marks them seen', (
    tester,
  ) async {
    final prefs = await _pump(
      tester,
      ['scene01:apple'],
      unseen: ['scene01:apple'],
    );

    // 未読の初発見には NEW バッジが付く。
    expect(
      find.byKey(const ValueKey('collection-new.scene01.apple')),
      findsOneWidget,
    );
    // 図鑑を開いたので永続側の unseen は既読化される（次回は出ない）。
    expect(
      prefs.getStringList('collection.slot1.unseen'),
      anyOf(isNull, isEmpty),
    );
  });

  testWidgets('shows the collected progress header', (tester) async {
    await _pump(tester, ['scene01:apple']);

    expect(find.byKey(const ValueKey('collection-progress')), findsOneWidget);
    // fake worlds: 合計 5 個（apple/duck/star + ball/flower）、収集 1 個。
    expect(find.textContaining('1/5'), findsOneWidget);
  });
}
