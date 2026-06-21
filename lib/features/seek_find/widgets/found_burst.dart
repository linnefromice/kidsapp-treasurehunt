import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 発見した宝の位置に重ねる、放射スパーク＋リング＋拡大のキラッ演出。
///
/// [intensity] は演出の派手さ（1.0 = 通常）。連鎖（A5）や「最後の 1 個」（B6）で
/// 大きくすると、キャンバス・スパーク数・継続時間が増えて山場を強調する。
class FoundBurst extends StatefulWidget {
  const FoundBurst({super.key, required this.color, this.intensity = 1.0});

  final Color color;
  final double intensity;

  @override
  State<FoundBurst> createState() => _FoundBurstState();
}

class _FoundBurstState extends State<FoundBurst>
    with SingleTickerProviderStateMixin {
  // 派手さに応じて継続時間を伸ばす（1.0→900ms / 2.0→1300ms、700〜1600 に制限）。
  late final int _durationMs = (900 + (widget.intensity - 1) * 400)
      .round()
      .clamp(700, 1600);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _durationMs),
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));

  // Fade the burst icon fully to 0 so it doesn't permanently obscure
  // the found target icon after the animation completes.
  late final Animation<double> _iconFade = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.5, 1.0)));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 派手さでキャンバス・スパーク数・アイコンを拡大（通常 160 / スパーク 8）。
    final canvas = 160.0 * widget.intensity;
    final sparkCount = (8 * widget.intensity).round().clamp(8, 20);
    final iconSize = 52.0 * (0.8 + 0.2 * widget.intensity);
    // OverflowBox gives the burst a square canvas, letting sparks radiate
    // beyond the target's narrow bounding box. The parent Stack must use
    // clipBehavior: Clip.none so the overflow is actually visible.
    return OverflowBox(
      minWidth: 0,
      minHeight: 0,
      maxWidth: canvas,
      maxHeight: canvas,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return CustomPaint(
            painter: _BurstPainter(_c.value, widget.color, sparkCount),
            child: Center(child: child),
          );
        },
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _iconFade,
            child: Icon(
              Icons.auto_awesome,
              color: widget.color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t, this.color, this.sparkCount);

  final double t;
  final Color color;

  /// 外側・内側それぞれのスパーク数（派手さに比例）。
  final int sparkCount;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.46;

    // Expanding ring (fades out quickly)
    final ringEnd = (t * 2.5).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy),
      maxR * ringEnd * 0.75,
      Paint()
        ..color = color.withValues(alpha: 0.55 * (1 - ringEnd))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Outer sparks: circles radiating outward in the treasure's color
    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * math.pi;
      final r = t * maxR;
      final opacity = (1.0 - t * 1.1).clamp(0.0, 1.0);
      final dotSize = 6.0 * (1.0 - t * 0.6);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        dotSize,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }

    // Inner sparks: lighter tint of the treasure's color, faster fade
    final innerColor = Color.lerp(color, Colors.white, 0.5)!;
    for (int i = 0; i < sparkCount; i++) {
      final angle = ((i + 0.5) / sparkCount) * 2 * math.pi;
      final r = t * maxR * 0.55;
      final opacity = (1.0 - t * 1.6).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        4.0 * (1.0 - t),
        Paint()..color = innerColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.t != t || old.color != color || old.sparkCount != sparkCount;
}
