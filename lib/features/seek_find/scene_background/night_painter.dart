part of 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';

// ──────────────────────────────────────────
// scene05: 夜の野原
// ──────────────────────────────────────────
class _NightPainter extends CustomPainter {
  const _NightPainter();

  static const List<List<double>> _kStars = [
    [0.06, 0.05],
    [0.18, 0.08],
    [0.30, 0.04],
    [0.42, 0.09],
    [0.55, 0.03],
    [0.67, 0.07],
    [0.78, 0.05],
    [0.90, 0.10],
    [0.12, 0.17],
    [0.35, 0.14],
    [0.58, 0.18],
    [0.82, 0.15],
    [0.05, 0.28],
    [0.25, 0.23],
    [0.47, 0.26],
    [0.72, 0.21],
    [0.94, 0.25],
    [0.15, 0.32],
    [0.60, 0.30],
    [0.88, 0.34],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Night sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E2A),
            Color(0xFF1A237E),
            Color(0xFF283593),
            Color(0xFF1B5E20),
          ],
          stops: [0.0, 0.50, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    for (final s in _kStars) {
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        2.2,
        starPaint,
      );
    }

    // Full moon
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.055,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    // Moon glow
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.075,
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.20),
    );

    // Ground (dark meadow)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF0D3B14)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.68,
                size.width,
                size.height * 0.32,
              ),
            ),
    );

    // Fireflies (small glowing dots)
    final firefly = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: 0.80);
    final fireflyGlow = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: 0.25);
    for (final pos in [
      [0.28, 0.55],
      [0.45, 0.62],
      [0.62, 0.50],
      [0.75, 0.58],
      [0.15, 0.60],
      [0.87, 0.53],
    ]) {
      final fx = pos[0] * size.width;
      final fy = pos[1] * size.height;
      canvas.drawCircle(Offset(fx, fy), 5.0, fireflyGlow);
      canvas.drawCircle(Offset(fx, fy), 2.5, firefly);
    }

    // Silhouette trees at horizon
    _drawSilhouetteTree(canvas, size, 0.05, 0.70, 0.07);
    _drawSilhouetteTree(canvas, size, 0.22, 0.68, 0.09);
    _drawSilhouetteTree(canvas, size, 0.78, 0.69, 0.08);
    _drawSilhouetteTree(canvas, size, 0.95, 0.71, 0.07);
  }

  void _drawSilhouetteTree(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
  ) {
    final x = cx * size.width;
    final y = cy * size.height;
    final radius = r * size.width;
    canvas.drawCircle(
      Offset(x, y - radius * 0.2),
      radius,
      Paint()..color = const Color(0xFF0A1F0A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y + radius * 0.5),
          width: radius * 0.25,
          height: radius * 0.8,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF0A1F0A),
    );
  }

  @override
  bool shouldRepaint(_NightPainter old) => false;
}
