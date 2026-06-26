import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_covers.dart';

SceneDef _scene({int targets = 6, String iconId = 'apple'}) => SceneDef(
  id: 'scene01',
  titleKey: 'scene.scene01.title',
  imageAsset: 'assets/scenes/scene01.png',
  targets: [
    for (var i = 0; i < targets; i++)
      FindTarget(
        id: 't$i',
        iconId: iconId,
        labelKey: 'target.$iconId',
        normalizedRect: Rect.fromLTWH(0.1 * i, 0.1, 0.1, 0.1),
      ),
  ],
  dummies: const [],
  hardDummies: const [],
);

const _pool = ['cover_box', 'cover_bush', 'cover_chest'];

void main() {
  test(
    'rate 1.0 covers every (non-rare) target with a cover from the pool',
    () {
      final out = _scene().withThemedCovers(_pool, Random(1), 1.0);
      for (final t in out.targets) {
        expect(t.coverIconId, isNotNull);
        expect(_pool, contains(t.coverIconId));
      }
    },
  );

  test('rate 0.0 leaves every target uncovered', () {
    final out = _scene().withThemedCovers(_pool, Random(2), 0.0);
    expect(out.targets.every((t) => t.coverIconId == null), isTrue);
  });

  test('uses multiple cover types across a stage (variety within a stage)', () {
    final out = _scene(targets: 12).withThemedCovers(_pool, Random(3), 1.0);
    final used = out.targets.map((t) => t.coverIconId).toSet();
    expect(used.length, greaterThan(1));
  });

  test('rare treasures are never covered (surprise stays visible)', () {
    final out = _scene(
      targets: 1,
      iconId: 'rare_gem',
    ).withThemedCovers(_pool, Random(4), 1.0);
    expect(out.targets.single.coverIconId, isNull);
  });

  test('empty pool is a no-op (no covers assigned)', () {
    final out = _scene().withThemedCovers(const [], Random(5), 1.0);
    expect(out.targets.every((t) => t.coverIconId == null), isTrue);
  });

  test('is deterministic for a given seed', () {
    List<String?> covers(int seed) => _scene()
        .withThemedCovers(_pool, Random(seed), 0.5)
        .targets
        .map((t) => t.coverIconId)
        .toList();
    expect(covers(9), covers(9));
  });

  test('coversForScene returns themed pools and falls back for unknown', () {
    expect(coversForScene('scene08'), contains('cover_shell')); // 海中
    expect(coversForScene('scene07'), contains('cover_star')); // 宇宙
    expect(coversForScene('scene01'), contains('cover_leaves')); // 森
    expect(coversForScene('does-not-exist'), isNotEmpty);
  });
}
