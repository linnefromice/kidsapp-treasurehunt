import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

Future<void> _pumpHome(WidgetTester tester, Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container.read(activeSlotProvider.notifier).select('slot1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TreasureMapScreen()),
    ),
  );
  // IMPORTANT: The "current" node has a repeating pulse animation.
  // pumpAndSettle() would hang. Use pump() only.
  await tester.pump();
}

void main() {
  testWidgets('fresh slot: scene01 current, others locked', (tester) async {
    await _pumpHome(tester, {
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('scene-node.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene03')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene04')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene05')), findsOneWidget);

    expect(find.byKey(const ValueKey('node-current.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene03')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene04')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene05')), findsOneWidget);

    expect(find.textContaining('0/9'), findsOneWidget);
  });

  testWidgets('cleared scene01 + unlocked scene02 reflects states', (
    tester,
  ) async {
    await _pumpHome(tester, {
      'progress.slot1.unlockedSceneIds': ['scene01', 'scene02'],
      'progress.slot1.clearedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('node-cleared.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-current.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene03')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene04')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene05')), findsOneWidget);

    expect(find.textContaining('1/9'), findsOneWidget);
  });

  testWidgets('multiple cleared scenes render without error', (tester) async {
    await _pumpHome(tester, {
      'progress.slot1.unlockedSceneIds': [
        'scene01',
        'scene02',
        'scene03',
        'scene04',
      ],
      'progress.slot1.clearedSceneIds': ['scene01', 'scene02', 'scene03'],
    });

    expect(find.byKey(const ValueKey('node-cleared.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-cleared.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-cleared.scene03')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-current.scene04')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene05')), findsOneWidget);

    expect(find.textContaining('3/9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all scenes cleared renders with no current marching footprints',
    (tester) async {
      final allIds = kSceneCatalog.map((e) => e.id).toList();
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': allIds,
        'progress.slot1.clearedSceneIds': allIds,
      });

      for (final entry in kSceneCatalog) {
        expect(
          find.byKey(ValueKey('node-cleared.${entry.id}')),
          findsOneWidget,
          reason: '${entry.id} should be cleared',
        );
      }
      expect(
        find.textContaining('${kSceneCatalog.length}/${kSceneCatalog.length}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('hard mode toggle', () {
    final allIds = kSceneCatalog.map((e) => e.id).toList();

    testWidgets('hidden until all scenes are cleared', (tester) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': ['scene01'],
      });
      expect(find.byKey(const ValueKey('map-mode-toggle')), findsNothing);
    });

    testWidgets('appears once every scene is cleared, defaults to normal', (
      tester,
    ) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': allIds,
        'progress.slot1.clearedSceneIds': allIds,
      });
      expect(find.byKey(const ValueKey('map-mode-toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('mode-normal')), findsOneWidget);
      expect(find.byKey(const ValueKey('mode-hard')), findsOneWidget);
      // Normal mode: all nodes cleared, counter shows 9/9.
      expect(
        find.byKey(const ValueKey('node-cleared.scene01')),
        findsOneWidget,
      );
      expect(find.textContaining('9/9'), findsOneWidget);
    });

    testWidgets('switching to hard reflects hard-cleared progress', (
      tester,
    ) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': allIds,
        'progress.slot1.clearedSceneIds': allIds,
        // Only scene01 hard-cleared so far.
        'progress.slot1.hardClearedSceneIds': ['scene01'],
      });

      await tester.tap(find.byKey(const ValueKey('mode-hard')));
      await tester.pump();

      // scene01 hard-cleared; the rest are tappable "current" hard nodes.
      expect(
        find.byKey(const ValueKey('node-cleared.scene01')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('node-current.scene02')),
        findsOneWidget,
      );
      // Hard counter: 1/9 with the fire marker.
      expect(find.textContaining('1/9'), findsOneWidget);
      expect(find.textContaining('🔥'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
