import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/treasure_category.dart';

const _worlds = [
  CollectionWorld(
    sceneId: 'scene01',
    titleKey: 'k1',
    iconIds: ['apple', 'duck', 'star', 'heart'],
  ),
  CollectionWorld(
    sceneId: 'scene02',
    titleKey: 'k2',
    iconIds: ['ball', 'flower', 'apple'],
  ),
];

void main() {
  test(
    'groups catalog icons by category (enum order), de-duped across worlds',
    () {
      final view = buildCategoryView(_worlds, const {});
      final cats = view.map((g) => g.category).toList();
      // 出現するカテゴリのみ・enum 順（animal, food, shape, toy, nature）。
      expect(cats, [
        TreasureCategory.animal, // duck
        TreasureCategory.food, // apple
        TreasureCategory.shape, // star, heart
        TreasureCategory.toy, // ball
        TreasureCategory.nature, // flower
      ]);
      final food = view.firstWhere((g) => g.category == TreasureCategory.food);
      expect(food.icons.map((e) => e.iconId), ['apple']); // 重複は畳む
      final shape = view.firstWhere(
        (g) => g.category == TreasureCategory.shape,
      );
      expect(shape.icons.map((e) => e.iconId).toSet(), {'star', 'heart'});
    },
  );

  test('marks an icon found if discovered in ANY world', () {
    final view = buildCategoryView(_worlds, {'scene02:apple'});
    final apple = view
        .firstWhere((g) => g.category == TreasureCategory.food)
        .icons
        .single;
    expect(apple.iconId, 'apple');
    expect(apple.found, isTrue); // scene02 で見つけた → なかまビューでも found
  });

  test('an icon not discovered anywhere is not found', () {
    final view = buildCategoryView(_worlds, {'scene01:duck'});
    final ball = view
        .firstWhere((g) => g.category == TreasureCategory.toy)
        .icons
        .single;
    expect(ball.found, isFalse);
  });
}
