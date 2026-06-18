import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 発見した宝の位置に重ねる、放射スパーク＋リング＋拡大のキラッ演出。
class FoundBurst extends StatefulWidget {
  const FoundBurst({super.key});

  @override
  State<FoundBurst> createState() => _FoundBurstState();
}

class _FoundBurstState extends State<FoundBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    // OverflowBox gives the burst a 160×160 canvas, letting sparks radiate
    // beyond the target's narrow bounding box. The parent Stack must use
    // clipBehavior: Clip.none so the overflow is actually visible.
    return OverflowBox(
      minWidth: 0,
      minHeight: 0,
      maxWidth: 160,
      maxHeight: 160,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return CustomPaint(
            painter: _BurstPainter(_c.value),
            child: Center(child: child),
          );
        },
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _iconFade,
            child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 52),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t);

  final double t;
  static const _kOuterCount = 8;
  static const _kInnerCount = 8;

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
        ..color = Colors.amber.withValues(alpha: 0.55 * (1 - ringEnd))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Outer sparks: amber circles radiating outward
    for (int i = 0; i < _kOuterCount; i++) {
      final angle = (i / _kOuterCount) * 2 * math.pi;
      final r = t * maxR;
      final opacity = (1.0 - t * 1.1).clamp(0.0, 1.0);
      final dotSize = 6.0 * (1.0 - t * 0.6);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        dotSize,
        Paint()..color = Colors.amber.withValues(alpha: opacity),
      );
    }

    // Inner sparks: smaller, offset angle, faster fade
    for (int i = 0; i < _kInnerCount; i++) {
      final angle = ((i + 0.5) / _kInnerCount) * 2 * math.pi;
      final r = t * maxR * 0.55;
      final opacity = (1.0 - t * 1.6).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        4.0 * (1.0 - t),
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
