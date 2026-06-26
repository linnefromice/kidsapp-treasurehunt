import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_shape.dart';

/// 粒の直径（dp）。
const double _kSparkleSize = 18.0;

/// Easy モードでなぞった指先に追従して出る、一瞬の小さなキラキラ粒子。
///
/// 1 粒 = 1 ウィジェット。生成直後に膨らんで消える短い演出だけを担い、
/// リストからの除去は親（`_SceneViewState`）が `MissBubble` と同じ方式で行う。
class TrailSparkle extends StatefulWidget {
  const TrailSparkle({
    super.key,
    required this.position,
    required this.color,
    this.shape = TrailShape.circle,
  });

  /// シーン座標上の生成位置（粒の中心）。
  final Offset position;

  /// 粒の色（設定で選んだトレイル色から解決済み）。
  final Color color;

  /// 粒の形（コスメ・#4）。既定は丸。
  final TrailShape shape;

  @override
  State<TrailSparkle> createState() => _TrailSparkleState();
}

class _TrailSparkleState extends State<TrailSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.6,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.9), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.0), weight: 80),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 毎フレームの再描画をシーン全体から隔離する（兄弟の _FoundGlow/HintGlow と同方針）。
    // FadeTransition/ScaleTransition は AnimatedBuilder+Opacity より合成コストが低い。
    return Positioned(
      left: widget.position.dx - _kSparkleSize / 2,
      top: widget.position.dy - _kSparkleSize / 2,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: CustomPaint(
                size: const Size.square(_kSparkleSize),
                painter: _SparklePainter(
                  shape: widget.shape,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 粒の形（丸/ほし/ハート）を、淡色でも見えるよう暗フチ＋やわらか発光付きで描く。
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.shape, required this.color});

  final TrailShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(shape, size);
    // やわらかい発光（淡色の視認も助ける）。
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // 本体塗り。
    canvas.drawPath(path, Paint()..color = color);
    // 暗フチ（明背景・淡色でも輪郭が立つ）。
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66000000),
    );
  }

  Path _shapePath(TrailShape shape, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    switch (shape) {
      case TrailShape.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: w / 2 - 1));
      case TrailShape.star:
        final path = Path();
        final r = w / 2 - 1;
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? r : r * 0.45;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = c + Offset(rr * math.cos(a), rr * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case TrailShape.heart:
        // 上 2 つの丸 ＋ 下の尖り。size に正規化。
        final path = Path();
        path.moveTo(w * 0.5, h * 0.86);
        path.cubicTo(w * 0.05, h * 0.55, w * 0.12, h * 0.12, w * 0.5, h * 0.33);
        path.cubicTo(w * 0.88, h * 0.12, w * 0.95, h * 0.55, w * 0.5, h * 0.86);
        return path..close();
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
