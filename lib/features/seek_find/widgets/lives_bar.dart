import 'package:flutter/material.dart';

/// pro モードの残機表示（♥♥♥）。表示専用。
/// 残っているぶんは塗りハート、失ったぶんは枠だけのハートで示す。
/// 読字に頼らず、減ったことが一目で分かる。
class LivesBar extends StatelessWidget {
  const LivesBar({super.key, required this.lives, required this.max});

  /// 残っている残機数（0..max）。
  final int lives;

  /// 満タンの残機数（ハートの総数）。
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'のこり $lives',
      child: Container(
        key: const ValueKey('lives-bar'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              Padding(
                padding: EdgeInsets.only(right: i == max - 1 ? 0 : 4),
                child: Icon(
                  i < lives ? Icons.favorite : Icons.favorite_border,
                  size: 26,
                  color: i < lives ? Colors.red.shade400 : Colors.black26,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
