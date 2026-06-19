import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/hard_mode.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';

SceneDef _baseScene() => const SceneDef(
  id: 'scene01',
  titleKey: 'scene.scene01.title',
  imageAsset: 'assets/scenes/scene01.png',
  targets: [
    FindTarget(
      id: 'apple',
      iconId: 'apple',
      labelKey: 'target.apple',
      normalizedRect: Rect.fromLTWH(0.1, 0.1, 0.12, 0.14),
    ),
    FindTarget(
      id: 'star',
      iconId: 'star',
      labelKey: 'target.star',
      normalizedRect: Rect.fromLTWH(0.5, 0.5, 0.12, 0.14),
    ),
  ],
  dummies: [
    DummyItem(
      id: 'leaf1',
      iconId: 'leaf',
      normalizedRect: Rect.fromLTWH(0.3, 0.2, 0.11, 0.13),
    ),
    DummyItem(
      id: 'key1',
      iconId: 'key',
      normalizedRect: Rect.fromLTWH(0.7, 0.4, 0.11, 0.13),
    ),
  ],
  hardDummies: [
    DummyItem(
      id: 'h_cake1',
      iconId: 'cake',
      normalizedRect: Rect.fromLTWH(0.46, 0.06, 0.11, 0.13),
    ),
  ],
);

void main() {
  group('gameModeFromQuery', () {
    test('"hard" maps to GameMode.hard', () {
      expect(gameModeFromQuery('hard'), GameMode.hard);
    });

    test('null / unknown / "normal" map to GameMode.normal', () {
      expect(gameModeFromQuery(null), GameMode.normal);
      expect(gameModeFromQuery('normal'), GameMode.normal);
      expect(gameModeFromQuery('whatever'), GameMode.normal);
    });
  });

  group('hardModeSceneDef', () {
    test('promotes every dummy into a find target (more to find)', () {
      final base = _baseScene();
      final hard = hardModeSceneDef(base);

      // 2 original targets + 2 promoted dummies = 4 targets.
      expect(hard.targets, hasLength(4));
      expect(hard.targets.map((t) => t.id), ['apple', 'star', 'leaf1', 'key1']);
    });

    test('promoted dummies keep their iconId and rect', () {
      final hard = hardModeSceneDef(_baseScene());
      final leaf = hard.targets.firstWhere((t) => t.id == 'leaf1');
      expect(leaf.iconId, 'leaf');
      expect(leaf.normalizedRect, const Rect.fromLTWH(0.3, 0.2, 0.11, 0.13));
      expect(leaf.labelKey, 'target.leaf');
    });

    test('dummies become the hard-only decoys', () {
      final hard = hardModeSceneDef(_baseScene());
      expect(hard.dummies.map((d) => d.id), ['h_cake1']);
      expect(hard.dummies.single.iconId, 'cake');
    });

    test('preserves id / titleKey / imageAsset (background unchanged)', () {
      final base = _baseScene();
      final hard = hardModeSceneDef(base);
      expect(hard.id, base.id);
      expect(hard.titleKey, base.titleKey);
      expect(hard.imageAsset, base.imageAsset);
    });

    test('does not mutate the base scene (immutability)', () {
      final base = _baseScene();
      hardModeSceneDef(base);
      expect(base.targets, hasLength(2));
      expect(base.dummies.map((d) => d.id), ['leaf1', 'key1']);
    });
  });

  group('kHardModeDisplayScale', () {
    test('is smaller than the normal display scale', () {
      expect(kHardModeDisplayScale, lessThan(kTreasureDisplayScale));
      expect(kHardModeDisplayScale, 0.8);
    });

    test('scaledTreasureRect shrinks the target around its center', () {
      const rect = Rect.fromLTWH(0.2, 0.2, 0.2, 0.2); // center (0.3, 0.3)
      final hard = scaledTreasureRect(rect, scale: kHardModeDisplayScale);
      expect(hard.center.dx, closeTo(0.3, 1e-9));
      expect(hard.center.dy, closeTo(0.3, 1e-9));
      expect(hard.width, closeTo(0.2 * kHardModeDisplayScale, 1e-9));
      // Hard target is strictly smaller than the normal display rect.
      expect(hard.width, lessThan(0.2 * kTreasureDisplayScale));
    });

    test('hit-test honors the hard (smaller) scale', () {
      const targets = [
        FindTarget(
          id: 'a',
          iconId: 'heart',
          labelKey: 'target.a',
          normalizedRect: Rect.fromLTWH(0.0, 0.0, 0.2, 0.2),
        ),
      ];
      const sceneSize = Size(1000, 1000);

      // normalized (0.21, 0.1): inside the 1.15x normal rect, but OUTSIDE the
      // 0.8x hard rect (right edge at 0.1 + 0.2*0.8/2 = 0.18). Smaller = harder.
      expect(
        findHitTargetId(
          scenePoint: const Offset(210, 100),
          sceneSize: sceneSize,
          targets: targets,
          foundIds: const {},
        ),
        'a',
      );
      expect(
        findHitTargetId(
          scenePoint: const Offset(210, 100),
          sceneSize: sceneSize,
          targets: targets,
          foundIds: const {},
          scale: kHardModeDisplayScale,
        ),
        isNull,
      );
    });
  });
}
