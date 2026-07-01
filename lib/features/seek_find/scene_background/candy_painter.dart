part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene15: おかしのくに（パステルのお菓子の丘）
// ──────────────────────────────────────────
class _CandyPainter extends CustomPainter {
  const _CandyPainter();

  // [cx, cy, r, colorIndex] ぺろぺろキャンディ（棒つき）。
  static const _kLollies = [
    [0.12, 0.30, 0.05, 0],
    [0.30, 0.22, 0.045, 1],
    [0.70, 0.24, 0.05, 2],
    [0.88, 0.32, 0.045, 3],
  ];

  static const _kLollyColors = [
    Color(0xFFF48FB1),
    Color(0xFF80DEEA),
    Color(0xFFFFF59D),
    Color(0xFFCE93D8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // パステルの空
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFFFF0F5)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(full),
    );
    // ぺろぺろキャンディ
    for (final c in _kLollies) {
      final cx = (c[0] as double) * size.width;
      final cy = (c[1] as double) * size.height;
      final r = (c[2] as double) * size.width;
      // 棒
      canvas.drawRect(
        Rect.fromLTWH(cx - r * 0.12, cy, r * 0.24, size.height * 0.2),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      // うずまきキャンディ
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = _kLollyColors[c[3] as int],
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.28
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }
    // クリームの丘（3 段）
    _hill(canvas, size, 0.66, const Color(0xFFF48FB1));
    _hill(canvas, size, 0.76, const Color(0xFFFFCC80));
    _hill(canvas, size, 0.86, const Color(0xFF8D6E63)); // チョコの地面
    // トッピング（カラースプレー）
    final rng = math.Random(15);
    const sprinkle = [
      Color(0xFFFFFFFF),
      Color(0xFFFFF59D),
      Color(0xFF80DEEA),
      Color(0xFFF48FB1),
    ];
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * (0.88 + rng.nextDouble() * 0.1);
      canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = sprinkle[i % 4]);
    }
  }

  void _hill(Canvas canvas, Size size, double topFrac, Color color) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * (topFrac + 0.04))
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * (topFrac - 0.05),
        size.width,
        size.height * (topFrac + 0.04),
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CandyPainter old) => false;
}
