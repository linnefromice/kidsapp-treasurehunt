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

Future<void> _pump(WidgetTester tester, List<String> discovered) async {
  SharedPreferences.setMockInitialValues({
    'save.createdSlotIds': ['slot1'],
    'collection.slot1.discovered': discovered,
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
}
