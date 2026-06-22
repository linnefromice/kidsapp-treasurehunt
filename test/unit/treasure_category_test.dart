import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/treasure_category.dart';

FindTarget _t(String id, String iconId) => FindTarget(
  id: id,
  iconId: iconId,
  labelKey: 'k',
  normalizedRect: const Rect.fromLTWH(0, 0, 0.1, 0.1),
);

void main() {
  group('categoryOf', () {
    test('maps the six target icons to a category', () {
      expect(categoryOf('apple'), TreasureCategory.food);
      expect(categoryOf('duck'), TreasureCategory.animal);
      expect(categoryOf('star'), TreasureCategory.shape);
      expect(categoryOf('heart'), TreasureCategory.shape);
      expect(categoryOf('ball'), TreasureCategory.toy);
      expect(categoryOf('flower'), TreasureCategory.nature);
    });

    test('returns null for icons without a category (e.g. decoys)', () {
      expect(categoryOf('leaf'), isNull);
      expect(categoryOf('unknown'), isNull);
    });
  });

  group('nextQuestCategory', () {
    final targets = [
      _t('apple_1', 'apple'), // food
      _t('duck_1', 'duck'), // animal
      _t('star_1', 'star'), // shape
      _t('heart_1', 'heart'), // shape
    ];

    test('is the category of the earliest unfound treasure', () {
      expect(nextQuestCategory(targets, const {}), TreasureCategory.food);
      expect(nextQuestCategory(targets, {'apple_1'}), TreasureCategory.animal);
      expect(
        nextQuestCategory(targets, {'apple_1', 'duck_1'}),
        TreasureCategory.shape,
      );
    });

    test('null when everything is found (quest is over)', () {
      expect(
        nextQuestCategory(targets, {'apple_1', 'duck_1', 'star_1', 'heart_1'}),
        isNull,
      );
    });

    test('skips targets whose icon has no category', () {
      final mixed = [_t('leaf_1', 'leaf'), _t('duck_1', 'duck')];
      expect(nextQuestCategory(mixed, const {}), TreasureCategory.animal);
    });
  });
}
