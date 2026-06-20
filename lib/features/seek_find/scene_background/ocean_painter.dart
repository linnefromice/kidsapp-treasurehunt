part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene02: 海
// ──────────────────────────────────────────
class _OceanPainter extends CustomPainter {
  const _OceanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.50),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0277BD), Color(0xFF29B6F6)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.50)),
    );

    // Deep sea
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.50, size.width, size.height * 0.25),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0288D1), Color(0xFF01579B)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.50,
                size.width,
                size.height * 0.25,
              ),
            ),
    );

    // Sandy beach
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE082), Color(0xFFFFCC02)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.72,
                size.width,
                size.height * 0.28,
              ),
            ),
    );

    // Wave layer 1
    _drawWaveBand(canvas, size, 0.66, 0.76, const Color(0xFF4FC3F7), 7);
    // Wave layer 2
    _drawWaveBand(
      canvas,
      size,
      0.59,
      0.68,
      const Color(0xFF0288D1).withValues(alpha: 0.7),
      5,
    );

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.10),
      size.width * 0.06,
      Paint()..color = const Color(0xFFFDD835),
    );

    // Clouds
    _drawCloud(canvas, size, 0.40, 0.08);
    _drawCloud(canvas, size, 0.75, 0.12);

    // Seashell on beach (decorative)
    _drawShell(canvas, size, 0.15, 0.85);
    _drawShell(canvas, size, 0.72, 0.88);
  }

  void _drawWaveBand(
    Canvas canvas,
    Size size,
    double y1,
    double y2,
    Color color,
    int waveCount,
  ) {
    final path = Path();
    final topY = y1 * size.height;
    final botY = y2 * size.height;
    path.moveTo(0, topY);
    final segW = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      path.quadraticBezierTo(
        (i + 0.5) * segW,
        topY - 12,
        (i + 1.0) * segW,
        topY,
      );
    }
    path.lineTo(size.width, botY);
    path.lineTo(0, botY);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCloud(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.05;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 1.15, y + r * 0.1), r * 0.82, paint);
    canvas.drawCircle(Offset(x - r * 1.05, y + r * 0.15), r * 0.74, paint);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.52), r * 0.76, paint);
  }

  void _drawShell(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.022;
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()..color = const Color(0xFFFFAB91),
    );
    canvas.drawCircle(
      Offset(x, y),
      r * 0.55,
      Paint()..color = const Color(0xFFFF7043),
    );
  }

  @override
  bool shouldRepaint(_OceanPainter old) => false;
}
