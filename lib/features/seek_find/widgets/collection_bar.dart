import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 画面下の図鑑。各 target に1枠、お題アイコンを表示し、見つけたら点灯する。
class CollectionBar extends StatelessWidget {
  const CollectionBar({
    super.key,
    required this.targetIds,
    required this.foundIds,
  });

  final List<String> targetIds;
  final Set<String> foundIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final id in targetIds)
            Padding(
              key: ValueKey('slot.$id'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.brown, width: 3),
                  color: foundIds.contains(id)
                      ? Colors.amber.shade200
                      : Colors.white,
                ),
                child: Icon(
                  targetIcon(id),
                  key: ValueKey(
                    foundIds.contains(id) ? 'found.$id' : 'unfound.$id',
                  ),
                  color: foundIds.contains(id)
                      ? Colors.amber.shade800
                      : Colors.grey.shade400,
                  size: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
