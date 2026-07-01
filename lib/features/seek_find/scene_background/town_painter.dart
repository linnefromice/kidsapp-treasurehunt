part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene14: ひるまの まち（明るい街なみ）
// ──────────────────────────────────────────
class _TownPainter extends CustomPainter {
  const _TownPainter();

  // [left, top, width, height, colorIndex] 正規化。屋根は上に三角。
  static const _kHouses = [
    [0.02, 0.52, 0.12, 0.30, 0],
    [0.15, 0.46, 0.11, 0.36, 1],
    [0.27, 0.55, 0.10, 0.27, 2],
    [0.39, 0.44, 0.12, 0.38, 3],
    [0.52, 0.53, 0.11, 0.29, 4],
    [0.64, 0.47, 0.11, 0.35, 0],
    [0.76, 0.55, 0.10, 0.27, 2],
    [0.87, 0.48, 0.12, 0.34, 1],
  ];

  static const _kWall = [
    Color(0xFFFFCC80), // orange
    Color(0xFFFFF59D), // yellow
    Color(0xFFB3E5FC), // light blue
    Color(0xFFF8BBD0), // pink
    Color(0xFFC8E6C9), // green
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // ひるまの空
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), Color(0xFFBBDEFB), Color(0xFFE1F5FE)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(full),
    );
    // おひさま
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.14),
      size.width * 0.05,
      Paint()..color = const Color(0xFFFFF176),
    );
    // 歩道（地面）
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    // 車道
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      Paint()..color = const Color(0xFF546E7A),
    );
    // 車道のセンターライン
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += size.width / 9) {
      canvas.drawLine(
        Offset(x, size.height * 0.905),
        Offset(x + size.width / 18, size.height * 0.905),
        line,
      );
    }
    // 家なみ
    for (final h in _kHouses) {
      _drawHouse(
        canvas,
        size,
        h[0] as double,
        h[1] as double,
        h[2] as double,
        h[3] as double,
        _kWall[h[4] as int],
      );
    }
  }

  void _drawHouse(
    Canvas canvas,
    Size size,
    double l,
    double t,
    double w,
    double h,
    Color wall,
  ) {
    final rect = Rect.fromLTWH(
      l * size.width,
      t * size.height,
      w * size.width,
      h * size.height,
    );
    canvas.drawRect(rect, Paint()..color = wall);
    // 屋根（三角）
    final roof = Path()
      ..moveTo(rect.left - w * size.width * 0.08, rect.top)
      ..lineTo(rect.center.dx, rect.top - h * size.height * 0.28)
      ..lineTo(rect.right + w * size.width * 0.08, rect.top)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFA1524A));
    // まど
    final win = Paint()..color = const Color(0xFF81D4FA);
    final ww = rect.width * 0.24;
    final wh = rect.height * 0.20;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.14,
        rect.top + rect.height * 0.16,
        ww,
        wh,
      ),
      win,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.60,
        rect.top + rect.height * 0.16,
        ww,
        wh,
      ),
      win,
    );
    // ドア
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.38,
        rect.top + rect.height * 0.58,
        rect.width * 0.24,
        rect.height * 0.42,
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
  }

  @override
  bool shouldRepaint(_TownPainter old) => false;
}
