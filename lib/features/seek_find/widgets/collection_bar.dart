import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 画面下の図鑑。同じアイコンの宝が複数あっても横並びにはせず、iconId ごとに
/// 1枠へまとめ、見つけた数を「found/total」でカウントアップ表示する。
/// 全部見つけた枠だけ点灯する。
class CollectionBar extends StatelessWidget {
  const CollectionBar({
    super.key,
    required this.targets,
    required this.foundIds,
  });

  final List<FindTarget> targets;
  final Set<String> foundIds;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByIcon(targets, foundIds);
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final g in groups)
            Padding(
              key: ValueKey('slot.${g.iconId}'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _CollectionSlot(group: g),
            ),
        ],
      ),
    );
  }
}

/// iconId 単位の収集状況。初出順を保つため List で返す。
class _IconGroup {
  const _IconGroup({
    required this.iconId,
    required this.found,
    required this.total,
  });

  final String iconId;
  final int found;
  final int total;

  bool get isComplete => found >= total;
  bool get hasMultiple => total > 1;
}

/// targets を iconId ごとに集計する。初出順を維持し、found は foundIds に
/// 含まれる target を数える。表示と判定の両方が同じ集計を使えるよう純関数。
List<_IconGroup> _groupByIcon(List<FindTarget> targets, Set<String> foundIds) {
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
      _IconGroup(iconId: iconId, found: found[iconId]!, total: total[iconId]!),
  ];
}

/// 図鑑1枠。アイコン本体（完成で点灯）+ 複数探しのときだけカウントバッジ。
class _CollectionSlot extends StatelessWidget {
  const _CollectionSlot({required this.group});

  final _IconGroup group;

  @override
  Widget build(BuildContext context) {
    final complete = group.isComplete;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown, width: 3),
              color: complete ? Colors.amber.shade200 : Colors.white,
            ),
            child: Icon(
              targetIcon(group.iconId),
              key: ValueKey(
                complete ? 'found.${group.iconId}' : 'unfound.${group.iconId}',
              ),
              color: complete ? Colors.amber.shade800 : Colors.grey.shade400,
              size: 36,
            ),
          ),
          if (group.hasMultiple)
            Positioned(
              right: -6,
              top: -6,
              child: _CountBadge(
                key: ValueKey('count.${group.iconId}'),
                found: group.found,
                total: group.total,
              ),
            ),
        ],
      ),
    );
  }
}

/// 「found/total」のカウントアップバッジ。濃い茶背景 + 白文字でコントラスト確保。
class _CountBadge extends StatelessWidget {
  const _CountBadge({super.key, required this.found, required this.total});

  final int found;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$found/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
