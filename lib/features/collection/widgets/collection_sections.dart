import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/widgets/collection_cell.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 全体の収集プログレス。完成で祝福（goal-gradient を内発的に）。
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.progress,
    required this.localeCode,
  });

  final CollectionProgress progress;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final complete = progress.isComplete;
    return Card(
      key: const ValueKey('collection-progress'),
      color: complete ? Colors.amber.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              complete ? Icons.emoji_events : Icons.menu_book,
              color: complete ? Colors.amber.shade800 : Colors.brown.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                complete
                    ? tr(localeCode, 'collection.allDone')
                    : '${tr(localeCode, 'collection.collected')} '
                          '${progress.found}/${progress.total}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 図鑑のビュー切替（ワールド別 / なかま別・D4）。
class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.byCategory,
    required this.localeCode,
    required this.onChanged,
  });

  final bool byCategory;
  final String localeCode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<bool>(
        key: const ValueKey('collection-view-toggle'),
        segments: [
          ButtonSegment(
            value: false,
            label: Text(tr(localeCode, 'collection.byWorld')),
            icon: const Icon(Icons.public),
          ),
          ButtonSegment(
            value: true,
            label: Text(tr(localeCode, 'collection.byCategory')),
            icon: const Icon(Icons.category),
          ),
        ],
        selected: {byCategory},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// なかま（カテゴリ）別の 1 グループ。カテゴリ絵＋ラベル＋宝セル（影絵→カラー）。
class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.group,
    required this.localeCode,
  });

  final CategoryGroup group;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('collection-category.${group.category.name}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(group.category.icon, color: Colors.brown.shade700),
                const SizedBox(width: 8),
                Text(
                  tr(localeCode, group.category.labelKey),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in group.icons)
                  CollectionCell(
                    sceneId: 'cat.${group.category.name}',
                    iconId: e.iconId,
                    discovered: e.found,
                    isNew: false,
                    localeCode: localeCode,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 見つけたレア宝（C4）を並べる「とくべつ」カード。見つけた分だけカラーで表示し、
/// 影絵（未収集）は出さない（サプライズ性を保つ・100% 判定にも影響しない）。
class RareSection extends StatelessWidget {
  const RareSection({
    super.key,
    required this.rareIconIds,
    required this.localeCode,
  });

  final List<String> rareIconIds;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('collection-rare'),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  tr(localeCode, 'collection.rare'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final iconId in rareIconIds)
                  Container(
                    key: ValueKey('collection-rare.$iconId'),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(
                            targetIcon(iconId),
                            color: targetColor(iconId),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
