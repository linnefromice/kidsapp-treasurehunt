part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene08: うみのなか
// ──────────────────────────────────────────
class _UnderseaPainter extends CustomPainter {
  const _UnderseaPainter();

  static const List<List<double>> _kBubbles = [
    [0.12, 0.20, 6],
    [0.20, 0.34, 4],
    [0.38, 0.12, 5],
    [0.52, 0.28, 7],
    [0.64, 0.16, 4],
    [0.78, 0.30, 6],
    [0.88, 0.18, 5],
    [0.30, 0.50, 5],
    [0.70, 0.52, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Fully submerged: teal near the surface to deep navy below
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF26C6DA),
            Color(0xFF0097A7),
            Color(0xFF01579B),
            Color(0xFF002F6C),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Light rays from the surface
    final rayPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (final cx in [0.25, 0.55, 0.80]) {
      final x = cx * size.width;
      final ray = Path()
        ..moveTo(x, 0)
        ..lineTo(x + size.width * 0.10, 0)
        ..lineTo(x + size.width * 0.02, size.height * 0.75)
        ..lineTo(x - size.width * 0.06, size.height * 0.75)
        ..close();
      canvas.drawPath(ray, rayPaint);
    }

    // Sandy sea floor
    final floorTop = size.height * 0.82;
    final floor = Path()
      ..moveTo(0, floorTop)
      ..quadraticBezierTo(
        size.width * 0.30,
        floorTop - size.height * 0.04,
        size.width * 0.55,
        floorTop,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        floorTop + size.height * 0.04,
        size.width,
        floorTop - size.height * 0.01,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFFE0C27C));

    // Seaweed on the floor
    // baseY pinned to the floor top (0.82) so stems grow from the surface.
    _drawSeaweed(canvas, size, 0.10, 0.82, 0.16);
    _drawSeaweed(canvas, size, 0.16, 0.82, 0.12);
    _drawSeaweed(canvas, size, 0.86, 0.82, 0.18);
    _drawSeaweed(canvas, size, 0.92, 0.82, 0.13);

    // Bubbles
    for (final b in _kBubbles) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(b[0] * size.width, b[1] * size.height),
        b[2].toDouble(),
        paint,
      );
    }
  }

  void _drawSeaweed(
    Canvas canvas,
    Size size,
    double cx,
    double baseY,
    double h,
  ) {
    final x = cx * size.width;
    final by = baseY * size.height;
    final height = h * size.height;
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(x, by)
      ..quadraticBezierTo(
        x - size.width * 0.03,
        by - height * 0.4,
        x,
        by - height * 0.6,
      )
      ..quadraticBezierTo(
        x + size.width * 0.03,
        by - height * 0.8,
        x,
        by - height,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_UnderseaPainter old) => false;
}
