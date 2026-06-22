import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 宝 1 つのセル。収集済みはカラー、未収集は影絵。初発見は new! バッジ付き（D8）。
/// ワールド別ページ・なかま別セクションの両方で使う共通セル。
class CollectionCell extends StatelessWidget {
  const CollectionCell({
    super.key,
    required this.sceneId,
    required this.iconId,
    required this.discovered,
    required this.isNew,
    required this.localeCode,
  });

  final String sceneId;
  final String iconId;
  final bool discovered;
  final bool isNew;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: ValueKey('collection-cell.$sceneId.$iconId'),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: discovered ? Colors.amber.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.brown.shade300, width: 2),
          ),
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: FittedBox(
                fit: BoxFit.contain,
                child: discovered
                    ? Icon(
                        targetIcon(iconId),
                        color: targetColor(iconId),
                        key: ValueKey('collection-found.$sceneId.$iconId'),
                      )
                    : UnfoundTreasureIcon(
                        key: ValueKey('collection-silhouette.$sceneId.$iconId'),
                        iconId: iconId,
                      ),
              ),
            ),
          ),
        ),
        if (discovered && isNew)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              key: ValueKey('collection-new.$sceneId.$iconId'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr(localeCode, 'collection.new'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
