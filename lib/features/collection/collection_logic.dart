import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/treasure_category.dart';

/// 図鑑（コレクション）全体の収集プログレス。
class CollectionProgress {
  const CollectionProgress({required this.found, required this.total});

  final int found;
  final int total;

  /// 全ワールドの全アイコンを集めきったか。
  bool get isComplete => total > 0 && found >= total;
}

/// [worlds]（図鑑カタログ）に対し [discovered]（`sceneId:iconId` 集合）が
/// どれだけ埋まっているかを数える純関数。カタログに無いエントリは数えない。
CollectionProgress collectionProgressOf(
  List<CollectionWorld> worlds,
  Set<String> discovered,
) {
  var total = 0;
  var found = 0;
  for (final w in worlds) {
    total += w.iconIds.length;
    for (final iconId in w.iconIds) {
      if (discovered.contains(
        CollectionRepository.entryKey(w.sceneId, iconId),
      )) {
        found++;
      }
    }
  }
  return CollectionProgress(found: found, total: total);
}

/// 図鑑「なかま（カテゴリ）」ビュー（D4）の 1 グループ。
class CategoryGroup {
  const CategoryGroup({required this.category, required this.icons});

  final TreasureCategory category;

  /// そのカテゴリの宝アイコンと、いずれかのワールドで発見済みか。
  final List<({String iconId, bool found})> icons;
}

/// カタログの宝アイコンを **カテゴリ** で束ねたビュー（D4）。各アイコンは
/// 「いずれかのワールドで発見済みか」で found を立てる（ワールド横断）。
/// カテゴリは [TreasureCategory] の enum 順、出現するものだけを返す。
List<CategoryGroup> buildCategoryView(
  List<CollectionWorld> worlds,
  Set<String> discovered,
) {
  // カタログ全アイコン（初出順・重複なし）。
  final allIcons = <String>[];
  for (final w in worlds) {
    for (final iconId in w.iconIds) {
      if (!allIcons.contains(iconId)) {
        allIcons.add(iconId);
      }
    }
  }
  // 発見済みアイコン（ワールド非依存）。エントリは `sceneId:iconId`。
  final foundIcons = discovered
      .map((e) => e.substring(e.indexOf(':') + 1))
      .toSet();

  final groups = <CategoryGroup>[];
  for (final category in TreasureCategory.values) {
    final icons = [
      for (final iconId in allIcons)
        if (categoryOf(iconId) == category)
          (iconId: iconId, found: foundIcons.contains(iconId)),
    ];
    if (icons.isNotEmpty) {
      groups.add(CategoryGroup(category: category, icons: icons));
    }
  }
  return groups;
}
