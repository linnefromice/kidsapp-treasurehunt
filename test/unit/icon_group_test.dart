import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/icon_group.dart';

const _kRect = Rect.fromLTWH(0, 0, 0.1, 0.1);

FindTarget _target(String id, {String? iconId}) => FindTarget(
  id: id,
  iconId: iconId ?? id,
  labelKey: id,
  normalizedRect: _kRect,
);

void main() {
  test('returns empty list for empty targets', () {
    expect(groupTargetsByIcon(const [], const {}), isEmpty);
  });

  test('one group per icon, preserving first-appearance order', () {
    final groups = groupTargetsByIcon([
      _target('star'),
      _target('apple'),
      _target('duck'),
    ], const {});
    expect(groups.map((g) => g.iconId), ['star', 'apple', 'duck']);
    expect(groups.every((g) => g.total == 1), isTrue);
    expect(groups.every((g) => g.found == 0), isTrue);
  });

  test('groups duplicate icons and counts found per group', () {
    final groups = groupTargetsByIcon(
      [
        _target('heart_1', iconId: 'heart'),
        _target('heart_2', iconId: 'heart'),
        _target('apple'),
      ],
      const {'heart_1', 'apple'},
    );

    final heart = groups.firstWhere((g) => g.iconId == 'heart');
    expect(heart.total, 2);
    expect(heart.found, 1);
    expect(heart.isComplete, isFalse);
    expect(heart.hasMultiple, isTrue);

    final apple = groups.firstWhere((g) => g.iconId == 'apple');
    expect(apple.total, 1);
    expect(apple.found, 1);
    expect(apple.isComplete, isTrue);
    expect(apple.hasMultiple, isFalse);
  });

  test('completes a duplicate group only when all are found', () {
    final groups = groupTargetsByIcon(
      [
        _target('heart_1', iconId: 'heart'),
        _target('heart_2', iconId: 'heart'),
      ],
      const {'heart_1', 'heart_2'},
    );
    final heart = groups.single;
    expect(heart.found, 2);
    expect(heart.isComplete, isTrue);
  });

  test('ignores foundIds that are not in targets', () {
    final groups = groupTargetsByIcon(
      [_target('apple')],
      const {'ghost', 'apple'},
    );
    expect(groups.single.found, 1);
    expect(groups.single.total, 1);
  });
}
