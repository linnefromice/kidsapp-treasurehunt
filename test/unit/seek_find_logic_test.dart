import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';

const _targets = [
  FindTarget(
    id: 'a',
    labelKey: 'target.a',
    normalizedRect: Rect.fromLTWH(0.0, 0.0, 0.2, 0.2),
  ),
  FindTarget(
    id: 'b',
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
}
