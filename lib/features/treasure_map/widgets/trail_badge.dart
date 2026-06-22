import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';

/// AppBar に表示する現在のトレイルスタイルバッジ。タップで設定画面へ。
class TrailBadge extends StatelessWidget {
  const TrailBadge({super.key, required this.setting, required this.onTap});

  final TrailSetting setting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'トレイル色設定',
      child: IconButton(
        key: const ValueKey('trail-badge'),
        // タップターゲット 60dp 以上（IconButton デフォルト 48dp を padding で補う）。
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
        onPressed: onTap,
        icon: switch (setting.style) {
          TrailStyle.solid => _TrailDot(color: setting.solidColor.baseColor),
          TrailStyle.rainbow3 => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                _TrailDot(color: setting.threeColors[i].baseColor, size: 14),
              ],
            ],
          ),
          TrailStyle.rainbowFull => Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

/// トレイルバッジ用の色付き丸。淡色でも埋もれないよう薄枠を付ける。
class _TrailDot extends StatelessWidget {
  const _TrailDot({required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
