import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_shape.dart';

/// ホーム（宝の地図）下部に置く、なぞりペンの大きな入口メニュー。
/// 現在のペン（色＋形）をプレビューしつつラベルで示し、1 タップで `/pen` へ。
/// キッズ UX 基準: タップターゲットは 60dp 以上、読字に頼らず絵＋色で示す。
class PenMenuButton extends StatelessWidget {
  const PenMenuButton({
    super.key,
    required this.setting,
    required this.shape,
    required this.label,
    required this.onTap,
  });

  /// 現在のトレイル色設定（プレビュー用）。
  final TrailSetting setting;

  /// 現在のなぞり形・筆（プレビュー用）。
  final TrailShape shape;

  /// ボタンの文言（例: 「ペン」）。
  final String label;

  final VoidCallback onTap;

  IconData get _shapeIcon => switch (shape) {
    TrailShape.circle => Icons.circle,
    TrailShape.star => Icons.star,
    TrailShape.heart => Icons.favorite,
    TrailShape.bubble => Icons.bubble_chart,
    TrailShape.flower => Icons.local_florist,
    TrailShape.neon => Icons.flare,
    TrailShape.ribbon => Icons.gesture,
    TrailShape.comet => Icons.mode_standby,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          key: const ValueKey('pen-menu-button'),
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amber.shade300, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 28, color: Colors.brown.shade600),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                _StylePreview(setting: setting),
                const SizedBox(width: 8),
                Icon(_shapeIcon, size: 22, color: Colors.amber.shade700),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 現在のトレイル色スタイルの小さなプレビュー（単色 / にじ3色 / にじフル）。
class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.setting});

  final TrailSetting setting;

  @override
  Widget build(BuildContext context) {
    return switch (setting.style) {
      TrailStyle.solid => _Dot(color: setting.solidColor.baseColor),
      TrailStyle.rainbow3 => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _Dot(color: setting.threeColors[i].baseColor, size: 14),
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
    };
  }
}

/// 色付き丸（淡色でも埋もれないよう薄枠付き）。
class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 22});

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
