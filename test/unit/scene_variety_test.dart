import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_ambient_variant.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

SceneDef _scene() => SceneDef(
  id: 'scene01',
  titleKey: 'k',
  imageAsset: 'a.png',
  targets: const [
    FindTarget(
      id: 'apple_1',
      iconId: 'apple',
      labelKey: 'target.apple',
      normalizedRect: Rect.fromLTWH(0.1, 0.1, 0.11, 0.13),
    ),
  ],
  dummies: [
    for (var i = 0; i < 6; i++)
      DummyItem(
        id: 'd$i',
        iconId: 'leaf',
        normalizedRect: Rect.fromLTWH(0.2 + 0.05 * i, 0.5, 0.10, 0.12),
      ),
  ],
  hardDummies: [
    for (var i = 0; i < 4; i++)
      DummyItem(
        id: 'h$i',
        iconId: 'gem',
        normalizedRect: Rect.fromLTWH(0.6, 0.1 * i, 0.10, 0.12),
        scale: 0.8,
      ),
  ],
);

void main() {
  group('withReseededDecoyIcons (C2)', () {
    test('keeps ids/positions/scale/counts, only icons change', () {
      final base = _scene();
      final out = base.withReseededDecoyIcons(Random(1));
      expect(out.dummies.length, base.dummies.length);
      expect(out.hardDummies.length, base.hardDummies.length);
      expect(
        out.dummies.map((d) => d.id).toList(),
        base.dummies.map((d) => d.id).toList(),
      );
      for (var i = 0; i < out.dummies.length; i++) {
        expect(out.dummies[i].normalizedRect, base.dummies[i].normalizedRect);
      }
      expect(out.hardDummies.first.scale, base.hardDummies.first.scale);
      // ターゲット（apple_1）は不変。
      expect(out.targets.single.iconId, 'apple');
    });

    test('reseeded decoy icons come from the pool and avoid target icons', () {
      final base = _scene();
      final out = base.withReseededDecoyIcons(Random(2));
      final targetIcons = base.targets.map((t) => t.iconId).toSet();
      for (final d in [...out.dummies, ...out.hardDummies]) {
        expect(kDecoyIconPool.contains(d.iconId), isTrue);
        expect(targetIcons.contains(d.iconId), isFalse);
        expect(hasTargetIcon(d.iconId), isTrue);
      }
    });

    test('is deterministic for a seed', () {
      final base = _scene();
      final a = base.withReseededDecoyIcons(Random(7));
      final b = base.withReseededDecoyIcons(Random(7));
      expect(
        a.dummies.map((d) => d.iconId).toList(),
        b.dummies.map((d) => d.iconId).toList(),
      );
    });
  });

  group('pickAmbientVariant (C3)', () {
    test('only normal has no tint; the others tint', () {
      expect(SceneAmbientVariant.normal.tint, isNull);
      for (final v in SceneAmbientVariant.values.where(
        (v) => v != SceneAmbientVariant.normal,
      )) {
        expect(v.tint, isNotNull, reason: '$v should tint');
      }
    });

    test('returns a member of the enum for many seeds', () {
      for (var seed = 0; seed < 30; seed++) {
        expect(
          SceneAmbientVariant.values,
          contains(pickAmbientVariant(Random(seed))),
        );
      }
    });
  });

  group('pool', () {
    test('decoy pool is disjoint from base target icons', () {
      const targetIcons = {'apple', 'duck', 'star', 'ball', 'flower', 'heart'};
      expect(kDecoyIconPool.toSet().intersection(targetIcons), isEmpty);
    });

    test('decoy pool icons are all known (render, no "?")', () {
      for (final id in kDecoyIconPool) {
        expect(hasTargetIcon(id), isTrue, reason: '$id must be known');
      }
    });
  });
}
