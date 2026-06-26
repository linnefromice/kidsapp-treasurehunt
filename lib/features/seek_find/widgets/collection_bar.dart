import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/icon_group.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';

/// 画面下の図鑑。同じアイコンの宝が複数あっても横並びにはせず、iconId ごとに
/// 1枠へまとめ、見つけた数を「found/total」でカウントアップ表示する。
/// その枠の宝を全て見つけたら点灯し、バッジはチェックマークに変わる。
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
    final groups = groupTargetsByIcon(targets, foundIds);
    // 背景色は画面端まで伸ばしつつ、中身だけを下端/左右のシステムインセット
    // （Android ナビゲーションバー等）ぶん押し上げる。top は上のシーン領域が
    // 守るので除外する。
    return Container(
      color: Colors.black.withValues(alpha: 0.05),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
        ),
      ),
    );
  }
}

/// 図鑑1枠。アイコン本体（完成で点灯）+ 複数探しのときだけカウントバッジ。
class _CollectionSlot extends StatelessWidget {
  const _CollectionSlot({required this.group});

  final IconGroup group;

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
            alignment: Alignment.center,
            child: SizedBox(
              width: 36,
              height: 36,
              child: TreasureGlyph(
                key: ValueKey(
                  complete
                      ? 'found.${group.iconId}'
                      : 'unfound.${group.iconId}',
                ),
                iconId: group.iconId,
                found: complete,
              ),
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
                complete: complete,
              ),
            ),
        ],
      ),
    );
  }
}

/// カウントアップバッジ。途中は「found/total」、完成したらチェックマーク。
/// 濃い茶背景 + 白文字/白アイコンでコントラストを確保し、読み上げ用に
/// Semantics ラベルを付ける（数字を読めない年齢でも音で進捗が分かる）。
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    super.key,
    required this.found,
    required this.total,
    required this.complete,
  });

  final int found;
  final int total;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: complete ? 'ぜんぶ みつけた' : '$found / $total こ みつけた',
      excludeSemantics: true,
      child: Container(
        padding: complete
            ? const EdgeInsets.all(3)
            : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.brown.shade700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: complete
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$found/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
