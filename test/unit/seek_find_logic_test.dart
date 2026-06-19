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
}
