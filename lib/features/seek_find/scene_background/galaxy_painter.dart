part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene13: ぎんが（うちゅうの別バージョン）
// ──────────────────────────────────────────
class _GalaxyPainter extends CustomPainter {
  const _GalaxyPainter();

  // 星の正規化座標（決定論的な星空）。scene07 とは別配置で銀河らしく散らす。
  static const List<List<double>> _kStars = [
    [0.06, 0.08],
    [0.16, 0.05],
    [0.27, 0.16],
    [0.38, 0.06],
    [0.48, 0.13],
    [0.59, 0.04],
    [0.69, 0.17],
    [0.80, 0.07],
    [0.91, 0.15],
    [0.12, 0.34],
    [0.34, 0.42],
    [0.55, 0.30],
    [0.76, 0.46],
    [0.93, 0.36],
    [0.22, 0.66],
    [0.44, 0.78],
    [0.63, 0.70],
    [0.84, 0.82],
    [0.97, 0.60],
    [0.05, 0.54],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    // Deep galaxy gradient (teal → violet → indigo) — scene07 より青紫寄り
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF04233A), Color(0xFF2A0A4A), Color(0xFF12002E)],
        ).createShader(full),
    );

    // Diagonal nebula band — soft translucent blobs
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.5);
    _drawNebula(
      canvas,
      Offset(-size.width * 0.18, 0),
      size.width * 0.26,
      const Color(0x66AB47BC),
    );
    _drawNebula(
      canvas,
      Offset(size.width * 0.06, size.height * 0.04),
      size.width * 0.22,
      const Color(0x5526C6DA),
    );
    _drawNebula(
      canvas,
      Offset(size.width * 0.24, -size.height * 0.02),
      size.width * 0.20,
      const Color(0x553F51B5),
    );
    canvas.restore();

    // Stars (two sizes for depth)
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < _kStars.length; i++) {
      final s = _kStars[i];
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        i.isEven ? 2.4 : 1.4,
        starPaint,
      );
    }

    // Two small planets
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.24),
      size.width * 0.055,
      Paint()..color = const Color(0xFF26A69A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.30),
      size.width * 0.07,
      Paint()..color = const Color(0xFFEC407A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.81, size.height * 0.27),
      size.width * 0.028,
      Paint()..color = const Color(0xFFF8BBD0),
    );

    // Comet streaking through the upper sky
    final head = Offset(size.width * 0.62, size.height * 0.18);
    final tail = Path()
      ..moveTo(head.dx, head.dy)
      ..lineTo(head.dx - size.width * 0.18, head.dy - size.height * 0.06)
      ..lineTo(head.dx - size.width * 0.16, head.dy + size.height * 0.02)
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.55),
    );
    canvas.drawCircle(head, size.width * 0.018, Paint()..color = Colors.white);
  }

  void _drawNebula(Canvas canvas, Offset center, double r, Color color) {
    // RadialGradient (center color → transparent) gives a soft nebula glow
    // without the per-frame cost of MaskFilter.blur. Safe here because the
    // painter renders once (shouldRepaint == false).
    final rect = Rect.fromCenter(
      center: center,
      width: r * 2.2,
      height: r * 1.1,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) => false;
}
