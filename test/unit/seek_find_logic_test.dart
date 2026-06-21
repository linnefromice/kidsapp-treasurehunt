import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';

const _targets = [
  FindTarget(
    id: 'a',
    iconId: 'heart',
    labelKey: 'target.a',
    normalizedRect: Rect.fromLTWH(0.0, 0.0, 0.2, 0.2),
  ),
  FindTarget(
    id: 'b',
    iconId: 'star',
    labelKey: 'target.b',
    normalizedRect: Rect.fromLTWH(0.5, 0.5, 0.2, 0.2),
  ),
];

void main() {
  const sceneSize = Size(800, 600);

  test('returns the target id when tap falls inside its rect', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60), // -> normalized (0.1, 0.1) inside 'a'
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, 'a');
  });

  test('hits a tap just outside the original rect but inside the scaled one', () {
    // 'a' rect right edge is x=0.2 (original). 0.21 is outside the raw rect but
    // inside the 1.15x display-scaled rect, so the enlarged target should hit.
    final id = findHitTargetId(
      scenePoint: const Offset(168, 60), // normalized (0.21, 0.1)
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, 'a');
  });

  test('scaledTreasureRect enlarges around the center', () {
    const rect = Rect.fromLTWH(0.2, 0.2, 0.2, 0.2); // center (0.3, 0.3)
    final scaled = scaledTreasureRect(rect);
    expect(scaled.center.dx, closeTo(0.3, 1e-9));
    expect(scaled.center.dy, closeTo(0.3, 1e-9));
    expect(scaled.width, closeTo(0.2 * kTreasureDisplayScale, 1e-9));
    expect(scaled.height, closeTo(0.2 * kTreasureDisplayScale, 1e-9));
  });

  test('scaledTreasureRect itemScale defaults to no extra scaling', () {
    const rect = Rect.fromLTWH(0.2, 0.2, 0.2, 0.2);
    // 引数省略時は kTreasureDisplayScale のみ（追加倍率なし）。
    expect(
      scaledTreasureRect(rect).width,
      closeTo(0.2 * kTreasureDisplayScale, 1e-9),
    );
    // 明示 1.0 は省略時と完全一致（宝の経路が不変であることの担保）。
    expect(
      scaledTreasureRect(rect, itemScale: 1.0).width,
      closeTo(scaledTreasureRect(rect).width, 1e-9),
    );
  });

  test('scaledTreasureRect itemScale multiplies size around center', () {
    const rect = Rect.fromLTWH(0.2, 0.2, 0.2, 0.2); // center (0.3, 0.3)
    final scaled = scaledTreasureRect(rect, itemScale: 0.5);
    // 中心は不変、サイズは kTreasureDisplayScale * itemScale 倍。
    expect(scaled.center.dx, closeTo(0.3, 1e-9));
    expect(scaled.center.dy, closeTo(0.3, 1e-9));
    expect(scaled.width, closeTo(0.2 * kTreasureDisplayScale * 0.5, 1e-9));
    expect(scaled.height, closeTo(0.2 * kTreasureDisplayScale * 0.5, 1e-9));
  });

  test('returns null when tap is on empty space', () {
    final id = findHitTargetId(
      scenePoint: const Offset(720, 60), // normalized (0.9, 0.1) -> empty
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, isNull);
  });

  test('skips already-found targets', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60),
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {'a'},
    );
    expect(id, isNull);
  });

  test('skips targets that are currently hidden (hard-mode blink)', () {
    // 'a' contains (0.1, 0.1), but it is blinking-hidden -> not hittable.
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60),
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
      hiddenIds: const {'a'},
    );
    expect(id, isNull);
  });

  test('hidden set does not affect visible targets', () {
    // 'a' is hidden but the tap is inside 'b' (visible) -> hits 'b'.
    final id = findHitTargetId(
      scenePoint: const Offset(480, 360), // normalized (0.6, 0.6) inside 'b'
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
      hiddenIds: const {'a'},
    );
    expect(id, 'b');
  });

  group('isPointOnHiddenTarget', () {
    test('true when the tap falls on a currently-hidden target', () {
      // (0.1, 0.1) is inside 'a'; 'a' is hidden -> on a hidden target.
      final on = isPointOnHiddenTarget(
        scenePoint: const Offset(80, 60),
        sceneSize: sceneSize,
        targets: _targets,
        hiddenIds: const {'a'},
      );
      expect(on, isTrue);
    });

    test('false when the tap falls on empty space', () {
      final on = isPointOnHiddenTarget(
        scenePoint: const Offset(720, 60), // normalized (0.9, 0.1) -> empty
        sceneSize: sceneSize,
        targets: _targets,
        hiddenIds: const {'a'},
      );
      expect(on, isFalse);
    });

    test('false when the tapped target is visible (not in hiddenIds)', () {
      // (0.1, 0.1) inside 'a' but only 'b' is hidden -> not on a hidden one.
      final on = isPointOnHiddenTarget(
        scenePoint: const Offset(80, 60),
        sceneSize: sceneSize,
        targets: _targets,
        hiddenIds: const {'b'},
      );
      expect(on, isFalse);
    });

    test('false when hiddenIds is empty', () {
      final on = isPointOnHiddenTarget(
        scenePoint: const Offset(80, 60),
        sceneSize: sceneSize,
        targets: _targets,
        hiddenIds: const {},
      );
      expect(on, isFalse);
    });
  });

  test('returns null for non-positive scene size', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60),
      sceneSize: Size.zero,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, isNull);
  });

  group('pickHintTargetId', () {
    test('returns null when all targets are found', () {
      final id = pickHintTargetId(
        targets: _targets,
        foundIds: const {'a', 'b'},
        random: Random(0),
      );
      expect(id, isNull);
    });

    test('returns the only unfound id when one target remains', () {
      final id = pickHintTargetId(
        targets: _targets,
        foundIds: const {'a'},
        random: Random(0),
      );
      expect(id, 'b');
    });

    test('never returns a found id: multiple seeds determinism check', () {
      for (int seed = 0; seed < 50; seed++) {
        final id = pickHintTargetId(
          targets: _targets,
          foundIds: const {'a'},
          random: Random(seed),
        );
        expect(id, 'b', reason: 'seed $seed should only pick unfound target');
      }
    });

    test('returns one of the unfound ids (any seed)', () {
      for (int seed = 0; seed < 50; seed++) {
        final id = pickHintTargetId(
          targets: _targets,
          foundIds: const {},
          random: Random(seed),
        );
        expect(
          {'a', 'b'}.contains(id),
          true,
          reason: 'seed $seed should pick from unfound targets',
        );
      }
    });

    test('returns null when targets list is empty', () {
      final id = pickHintTargetId(
        targets: const [],
        foundIds: const {},
        random: Random(0),
      );
      expect(id, isNull);
    });
  });

  group('treasureBlinkOpacity', () {
    test('is fully visible at the start of a target cycle', () {
      // slot 0 at clock 0.0 -> phase 0.0 -> visible plateau.
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: 0.0),
        closeTo(1.0, 1e-9),
      );
    });

    test('is fully hidden in the disappear window', () {
      // slot 0 at clock 0.85 -> phase 0.85 -> hidden interval [0.62, 0.92).
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: 0.85),
        closeTo(0.0, 1e-9),
      );
    });

    test('hidden window is widened (phase 0.65 now fully hidden)', () {
      // 消失時間を長くしたため、以前は可視だった 0.65 も消失域 [0.62, 0.92) に入る。
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: 0.65),
        closeTo(0.0, 1e-9),
      );
    });

    test('fades through the visible threshold (half-faded = 0.5)', () {
      // slot 0 at clock 0.585 -> midpoint of [0.55, 0.62) fade-out.
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: 0.585),
        closeTo(0.5, 1e-9),
      );
    });

    test('fades back through the visible threshold on reappear (= 0.5)', () {
      // slot 0 at clock 0.96 -> phase 0.96 -> midpoint of [0.92, 1.0) fade-in.
      // This is the point where a vanished target becomes hittable again.
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: 0.96),
        closeTo(0.5, 1e-9),
      );
    });

    test('staggers phase so not all targets vanish at once', () {
      // At clock 0.85 slot 0 is hidden, but slot 1 (offset 0.25) is visible.
      const clock = 0.85;
      expect(
        treasureBlinkOpacity(slot: 0, count: 4, clock: clock),
        closeTo(0.0, 1e-9),
      );
      expect(
        treasureBlinkOpacity(slot: 1, count: 4, clock: clock),
        closeTo(1.0, 1e-9),
        reason: 'a different phase must keep some treasure on screen',
      );
    });

    test('guards against zero/negative count (no division by zero)', () {
      // offset becomes 0; result follows the clock phase directly.
      expect(
        treasureBlinkOpacity(slot: 0, count: 0, clock: 0.0),
        closeTo(1.0, 1e-9),
      );
    });
  });

  group('comboBurstScale (連鎖演出の派手さ)', () {
    test('first find is plain (1.0)', () {
      expect(comboBurstScale(0), closeTo(1.0, 1e-9));
      expect(comboBurstScale(1), closeTo(1.0, 1e-9));
    });

    test('escalates with consecutive finds', () {
      expect(comboBurstScale(2), closeTo(1.15, 1e-9));
      expect(comboBurstScale(4), closeTo(1.45, 1e-9));
    });

    test('caps so it never gets absurd', () {
      expect(comboBurstScale(5), closeTo(1.6, 1e-9));
      expect(comboBurstScale(100), closeTo(1.6, 1e-9));
    });

    test('the grand finale is always the most lavish burst', () {
      // 「最後の1個」は連鎖の上限より必ず派手にする。
      expect(kGrandFinaleBurstIntensity, greaterThan(comboBurstScale(1000)));
    });
  });
}
