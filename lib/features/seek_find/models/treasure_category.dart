import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';

/// 宝のざっくりした仲間分け（お題発見 A3・I Spy 型のお題に使う）。
/// 「○○ を さがそう」の○○。読字に依存しないよう、表示は [icon]（絵）＋音で行う。
enum TreasureCategory {
  animal('quest.animal', Icons.pets),
  food('quest.food', Icons.restaurant),
  shape('quest.shape', Icons.category),
  toy('quest.toy', Icons.toys),
  nature('quest.nature', Icons.local_florist);

  const TreasureCategory(this.labelKey, this.icon);

  /// i18n キー（`quest.<id>`）。
  final String labelKey;

  /// お題バナーに出す代表アイコン（読字不要の「絵」）。
  final IconData icon;
}

/// 宝アイコン id → カテゴリ。ターゲットに使う 6 種のみ定義（おとり等は null）。
const Map<String, TreasureCategory> _kCategoryByIcon = {
  'apple': TreasureCategory.food,
  'duck': TreasureCategory.animal,
  'star': TreasureCategory.shape,
  'heart': TreasureCategory.shape,
  'ball': TreasureCategory.toy,
  'flower': TreasureCategory.nature,
};

/// アイコン id のカテゴリ（未定義は null）。
TreasureCategory? categoryOf(String iconId) => _kCategoryByIcon[iconId];

/// 今の「お題」= 未発見で最も手前にある宝のカテゴリ（無ければ null）。
/// ソフトガイド: どれを見つけても進むので、罰や強制はしない。
TreasureCategory? nextQuestCategory(
  List<FindTarget> targets,
  Set<String> foundIds,
) {
  for (final t in targets) {
    if (foundIds.contains(t.id)) continue;
    final category = categoryOf(t.iconId);
    if (category != null) return category;
  }
  return null;
}
