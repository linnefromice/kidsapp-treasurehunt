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

/// 粒の形（丸/ほし/ハート/あわ/はな/ネオン）を、淡色でも見えるよう暗フチ＋
/// やわらか発光付きで描く。ネオンは発光を強め、あわは光沢ハイライトを足す。
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.shape, required this.color});

  final TrailShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(shape, size);
    final neon = shape == TrailShape.neon;
    // やわらかい発光（淡色の視認も助ける）。ネオンは強めに光らせる。
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: neon ? 0.9 : 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, neon ? 7 : 4),
    );
    // 本体塗り（ネオンは中心を白めに）。
    canvas.drawPath(
      path,
      Paint()..color = neon ? Color.lerp(color, Colors.white, 0.35)! : color,
    );
    // あわ: 光沢ハイライト。
    if (shape == TrailShape.bubble) {
      canvas.drawCircle(
        Offset(size.width * 0.36, size.height * 0.34),
        size.width * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
    // 暗フチ（明背景・淡色でも輪郭が立つ）。ネオンは縁なし（発光優先）。
    if (!neon) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x66000000),
      );
    }
  }

  Path _shapePath(TrailShape shape, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    switch (shape) {
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
      case TrailShape.flower:
        // 5 枚の花びら（丸）＋ 中心。小さい粒なので丸の集合で十分「花」に見える。
        final path = Path();
        final pr = w * 0.16;
        final d = w * 0.3;
        for (var k = 0; k < 5; k++) {
          final a = -math.pi / 2 + k * 2 * math.pi / 5;
          path.addOval(
            Rect.fromCircle(
              center: c + Offset(d * math.cos(a), d * math.sin(a)),
              radius: pr,
            ),
          );
        }
        return path..addOval(Rect.fromCircle(center: c, radius: pr));
      // circle / bubble / neon / ストローク（ribbon/comet・ここでは未使用）は丸。
      case TrailShape.circle:
      case TrailShape.bubble:
      case TrailShape.neon:
      case TrailShape.ribbon:
      case TrailShape.comet:
        return Path()..addOval(Rect.fromCircle(center: c, radius: w / 2 - 1));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

/// 連続ストローク（リボン/コメット）のトレイル。最近のなぞり点を 1 本の線で結び、
/// 古い側ほど細く・薄くフェードさせる。コメットは頭を太く、リボンは一定幅。
/// 点・色は親（`_SceneViewState` の `_trailSparkles`）から渡される（古い順）。
class TrailStroke extends StatelessWidget {
  const TrailStroke({super.key, required this.points, required this.comet});

  /// なぞり点（古い順）。位置はシーン座標、色は粒ごとに解決済み。
  final List<({Offset position, Color color})> points;

  /// true=コメット（頭を太く）/ false=リボン（一定幅）。
  final bool comet;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StrokePainter(points: points, comet: comet),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.points, required this.comet});

  final List<({Offset position, Color color})> points;
  final bool comet;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final n = points.length;
    for (var i = 1; i < n; i++) {
      // t: 0（最古=尾）..1（最新=頭）。
      final t = i / (n - 1);
      final width = comet ? (2.0 + 16.0 * t) : 9.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = points[i].color.withValues(alpha: 0.85 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawLine(points[i - 1].position, points[i].position, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}
