part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene03: 夜の街
// ──────────────────────────────────────────
class _CityPainter extends CustomPainter {
  const _CityPainter();

  static const _kBuildings = [
    // [left, top, width, height] normalized
    [0.00, 0.38, 0.10, 0.44],
    [0.11, 0.50, 0.08, 0.32],
    [0.20, 0.28, 0.13, 0.54],
    [0.34, 0.48, 0.09, 0.34],
    [0.44, 0.33, 0.11, 0.49],
    [0.56, 0.24, 0.10, 0.58],
    [0.67, 0.42, 0.10, 0.40],
    [0.78, 0.30, 0.11, 0.52],
    [0.90, 0.46, 0.10, 0.36],
  ];

  static const List<List<double>> _kStars = [
    [0.08, 0.06],
    [0.22, 0.10],
    [0.38, 0.05],
    [0.52, 0.09],
    [0.68, 0.04],
    [0.80, 0.11],
    [0.93, 0.07],
    [0.15, 0.18],
    [0.48, 0.16],
    [0.75, 0.19],
    [0.90, 0.22],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Night-to-dusk sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B4B),
            Color(0xFF3949AB),
            Color(0xFFE64A19),
            Color(0xFFFF8F00),
          ],
          stops: [0.0, 0.45, 0.72, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final s in _kStars) {
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        2.0,
        starPaint,
      );
    }

    // Moon
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.13),
      size.width * 0.04,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    // Moon crescent mask
    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.11),
      size.width * 0.034,
      Paint()..color = const Color(0xFF1A237E),
    );

    // Road
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16),
      Paint()..color = const Color(0xFF263238),
    );
    // Road center line
    final linePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.7)
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(
        Offset(x, size.height * 0.921),
        Offset(x + size.width / 16, size.height * 0.921),
        linePaint,
      );
    }

    // Buildings (silhouettes)
    for (final b in _kBuildings) {
      _drawBuilding(canvas, size, b[0], b[1], b[2], b[3]);
    }
  }

  void _drawBuilding(
    Canvas canvas,
    Size size,
    double l,
    double t,
    double w,
    double h,
  ) {
    final rect = Rect.fromLTWH(
      l * size.width,
      t * size.height,
      w * size.width,
      h * size.height,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0A0E2A));

    // Windows
    final winW = w * size.width * 0.18;
    final winH = h * size.height * 0.08;
    const cols = 2;
    final rows = math.max(2, (h * 10).floor());
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final lit = (row + col) % 3 != 0;
        final wx =
            rect.left + col * (w * size.width * 0.38) + w * size.width * 0.15;
        final wy =
            rect.top + row * (h * size.height * 0.18) + h * size.height * 0.08;
        canvas.drawRect(
          Rect.fromLTWH(wx, wy, winW, winH),
          Paint()
            ..color = lit
                ? Colors.yellow.withValues(alpha: 0.75)
                : Colors.blueGrey.shade900.withValues(alpha: 0.4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) => false;
}
