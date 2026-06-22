import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

void main() {
  test('there is at least one rare treasure', () {
    expect(kRareTreasures, isNotEmpty);
  });

  test('rare icon ids are unique and recognised by isRareIcon', () {
    final ids = kRareTreasures.map((r) => r.iconId).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(isRareIcon(id), isTrue);
    }
  });

  test('base (non-rare) icons are not flagged as rare', () {
    for (final id in ['apple', 'duck', 'star', 'leaf', 'gem']) {
      expect(isRareIcon(id), isFalse, reason: '$id must not be rare');
    }
  });

  test('every rare icon is a known icon (renders, no "?")', () {
    for (final r in kRareTreasures) {
      expect(
        hasTargetIcon(r.iconId),
        isTrue,
        reason: '${r.iconId} must be in target_icons.dart',
      );
    }
  });

  test('pickRare returns a member of the pool for many seeds', () {
    for (var seed = 0; seed < 30; seed++) {
      expect(kRareTreasures, contains(pickRare(Random(seed))));
    }
  });
}
