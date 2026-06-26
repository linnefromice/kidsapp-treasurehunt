import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/treasure_category.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/theme/kids_theme.dart';

/// お題発見（A3）のソフトガイド・バナー。「これを さがそう」を 🔍＋**宝の絵**（I-Spy）＋
/// なかまラベルで示す（読字に依存しない）。表示専用（非タップ）で、強制も罰も無い。
class QuestBanner extends StatelessWidget {
  const QuestBanner({
    super.key,
    required this.iconId,
    required this.category,
    required this.localeCode,
  });

  /// いま探す宝の icon id（具体ターゲットの絵を見せる）。
  final String iconId;
  final TreasureCategory category;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    // 表示専用のガイド（非タップ）。発見音（報酬）を流用しないことで「発見＝報酬音」
    // の連合を汚さない。読字に依存しないよう 🔍＋宝の絵＋なかまラベルで示す。
    return Material(
      color: KidsTheme.toggleSurface,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 26, color: Colors.brown.shade600),
            const SizedBox(width: 8),
            // 具体ターゲットの絵（I-Spy）。これを探す、が一目で分かる。
            SizedBox(
              width: 34,
              height: 34,
              child: TreasureGlyph(
                key: ValueKey('quest-target.$iconId'),
                iconId: iconId,
                found: true,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr(localeCode, category.labelKey),
              key: ValueKey('quest-label.${category.name}'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
