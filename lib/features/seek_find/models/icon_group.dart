import 'package:flutter/foundation.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';

/// iconId 単位の収集状況。同じアイコンの宝が複数あっても1グループにまとめ、
/// 見つけた数 [found] と必要数 [total] を持つ。図鑑のカウントアップ表示に使う。
@immutable
class IconGroup {
  const IconGroup({
    required this.iconId,
    required this.found,
    required this.total,
  });

  final String iconId;
  final int found;
  final int total;

  /// そのアイコンの宝を全て見つけたか。
  bool get isComplete => found >= total;

  /// 同じアイコンが複数ある（カウントアップ表示が要る）か。
  bool get hasMultiple => total > 1;
}

/// [targets] を iconId ごとに集計する純関数。初出順を維持し、[found] は
/// [foundIds] に含まれる target を数える。[foundIds] に targets 外の id が
/// 混じっていても無視する（集計は targets 基準）。
List<IconGroup> groupTargetsByIcon(
  List<FindTarget> targets,
  Set<String> foundIds,
) {
  final order = <String>[];
  final total = <String, int>{};
  final found = <String, int>{};
  for (final t in targets) {
    if (!total.containsKey(t.iconId)) {
      order.add(t.iconId);
      total[t.iconId] = 0;
      found[t.iconId] = 0;
    }
    total[t.iconId] = total[t.iconId]! + 1;
    if (foundIds.contains(t.id)) {
      found[t.iconId] = found[t.iconId]! + 1;
    }
  }
  return [
    for (final iconId in order)
      IconGroup(iconId: iconId, found: found[iconId]!, total: total[iconId]!),
  ];
}
