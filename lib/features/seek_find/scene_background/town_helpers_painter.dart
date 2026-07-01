part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene18: まちのおしごと（消防署・交番のある通り）
// ──────────────────────────────────────────
class _TownHelpersPainter extends CustomPainter {
  const _TownHelpersPainter();

  // [left, top, width, height, colorIndex] しせつ（消防署/交番など）。
  static const _kStations = [
    [0.03, 0.44, 0.20, 0.38, 0],
    [0.28, 0.50, 0.17, 0.32, 1],
    [0.60, 0.46, 0.20, 0.36, 2],
    [0.83, 0.52, 0.15, 0.30, 1],
  ];

  static const _kFacade = [
    Color(0xFFEF9A9A), // 消防署（赤系）
    Color(0xFF90CAF9), // 交番（青系）
    Color(0xFFFFE082), // 役所（黄系）
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(full),
    );
    // 歩道
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    // 車道
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16),
      Paint()..color = const Color(0xFF546E7A),
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += size.width / 9) {
      canvas.drawLine(
        Offset(x, size.height * 0.92),
        Offset(x + size.width / 18, size.height * 0.92),
        line,
      );
    }
    // しせつ
    for (final b in _kStations) {
      _facade(
        canvas,
        size,
        b[0] as double,
        b[1] as double,
        b[2] as double,
        b[3] as double,
        _kFacade[b[4] as int],
      );
    }
  }

  void _facade(
    Canvas canvas,
    Size size,
    double l,
    double t,
    double w,
    double h,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      l * size.width,
      t * size.height,
      w * size.width,
      h * size.height,
    );
    canvas.drawRect(rect, Paint()..color = color);
    // 屋根の帯
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    // 大きなガレージ扉（はたらく車の出入口）
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.18,
        rect.top + rect.height * 0.42,
        rect.width * 0.64,
        rect.height * 0.58,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_TownHelpersPainter old) => false;
}
