import 'package:flutter/material.dart';

/// 画面下の図鑑。各 target に1枠、見つけたら埋まる。
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
                child: foundIds.contains(id)
                    ? Icon(
                        Icons.star,
                        key: ValueKey('found.$id'),
                        color: Colors.amber.shade800,
                        size: 36,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
