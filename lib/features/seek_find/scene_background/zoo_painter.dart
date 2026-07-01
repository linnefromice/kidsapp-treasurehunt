part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene16: どうぶつえん（草地と柵とサファリテント）
// ──────────────────────────────────────────
class _ZooPainter extends CustomPainter {
  const _ZooPainter();

  static const _kBushes = [
    [0.08, 0.62, 0.10],
    [0.28, 0.66, 0.08],
    [0.55, 0.63, 0.11],
    [0.80, 0.66, 0.09],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // あかるい空
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF90CAF9), Color(0xFFC5E1A5)],
          stops: [0.0, 0.62],
        ).createShader(full),
    );
    // 草地
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      Paint()..color = const Color(0xFF7CB342),
    );
    // サファリテント（しましま屋根）
    _tent(canvas, size, 0.36, 0.30);
    // 柵
    final post = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final railY1 = size.height * 0.70;
    final railY2 = size.height * 0.76;
    canvas.drawLine(Offset(0, railY1), Offset(size.width, railY1), post);
    canvas.drawLine(Offset(0, railY2), Offset(size.width, railY2), post);
    for (double x = size.width * 0.04; x < size.width; x += size.width / 12) {
      canvas.drawLine(
        Offset(x, size.height * 0.66),
        Offset(x, size.height * 0.80),
        post,
      );
    }
    // しげみ
    for (final b in _kBushes) {
      _bush(canvas, size, b[0], b[1], b[2]);
    }
  }

  void _tent(Canvas canvas, Size size, double cx, double topFrac) {
    final x = cx * size.width;
    final top = topFrac * size.height;
    final w = size.width * 0.28;
    final baseY = size.height * 0.62;
    // 屋根の三角
    final roof = Path()
      ..moveTo(x - w / 2, baseY)
      ..lineTo(x, top)
      ..lineTo(x + w / 2, baseY)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFFFF3E0));
    // しましま
    final stripe = Paint()..color = const Color(0xFFE57373);
    for (var i = 0; i < 5; i++) {
      final f = i / 5;
      final sx = x - w / 2 + w * f;
      final tri = Path()
        ..moveTo(sx, baseY)
        ..lineTo(x, top)
        ..lineTo(sx + w / 10, baseY)
        ..close();
      if (i.isEven) canvas.drawPath(tri, stripe);
    }
  }

  void _bush(Canvas canvas, Size size, double cx, double cy, double r) {
    final x = cx * size.width;
    final y = cy * size.height;
    final rr = r * size.width;
    final paint = Paint()..color = const Color(0xFF558B2F);
    canvas.drawCircle(Offset(x - rr * 0.5, y), rr * 0.6, paint);
    canvas.drawCircle(Offset(x + rr * 0.5, y), rr * 0.6, paint);
    canvas.drawCircle(Offset(x, y - rr * 0.3), rr * 0.7, paint);
  }

  @override
  bool shouldRepaint(_ZooPainter old) => false;
}
