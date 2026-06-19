import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 画面下の図鑑。各 target に1枠、iconId のアイコンを表示し、見つけたら点灯する。
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
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final t in targets)
            Padding(
              key: ValueKey('slot.${t.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.brown, width: 3),
                  color: foundIds.contains(t.id)
                      ? Colors.amber.shade200
                      : Colors.white,
                ),
                child: Icon(
                  targetIcon(t.iconId),
                  key: ValueKey(
                    foundIds.contains(t.id) ? 'found.${t.id}' : 'unfound.${t.id}',
                  ),
                  color: foundIds.contains(t.id)
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
