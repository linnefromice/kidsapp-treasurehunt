part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene17: ゆうえんち（観覧車とテントと万国旗）
// ──────────────────────────────────────────
class _ParkPainter extends CustomPainter {
  const _ParkPainter();

  static const _kBunting = [
    Color(0xFFEF5350),
    Color(0xFFFFEE58),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // 夕暮れのわくわく空
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E57C2), Color(0xFFFF8A65), Color(0xFFFFE0B2)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(full),
    );
    // 地面
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFF8D6E63),
    );
    // 観覧車
    _ferrisWheel(canvas, size, 0.24, 0.44, size.width * 0.14);
    // ストライプのテント
    _tent(canvas, size, 0.66, 0.58, size.width * 0.22);
    // 万国旗（上部）
    _bunting(canvas, size);
  }

  void _ferrisWheel(Canvas canvas, Size size, double cx, double cy, double r) {
    final c = Offset(cx * size.width, cy * size.height);
    // 支柱
    final leg = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 5;
    canvas.drawLine(c, Offset(c.dx - r * 0.5, size.height * 0.78), leg);
    canvas.drawLine(c, Offset(c.dx + r * 0.5, size.height * 0.78), leg);
    // 外輪
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    // スポークとゴンドラ
    const gondola = [
      Color(0xFFEF5350),
      Color(0xFFFFEE58),
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFFAB47BC),
      Color(0xFFFF7043),
    ];
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      canvas.drawLine(
        c,
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(p, r * 0.14, Paint()..color = gondola[i % 6]);
    }
    canvas.drawCircle(c, r * 0.08, Paint()..color = const Color(0xFF455A64));
  }

  void _tent(Canvas canvas, Size size, double cx, double topFrac, double w) {
    final x = cx * size.width;
    final top = topFrac * size.height;
    final baseY = size.height * 0.78;
    final roof = Path()
      ..moveTo(x - w / 2, baseY)
      ..lineTo(x, top)
      ..lineTo(x + w / 2, baseY)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFFFF3E0));
    final stripe = Paint()..color = const Color(0xFFEF5350);
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

  void _bunting(Canvas canvas, Size size) {
    final y = size.height * 0.10;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y + size.height * 0.02),
      line,
    );
    final step = size.width / 14;
    for (var i = 0; i < 14; i++) {
      final fx = i * step;
      final flag = Path()
        ..moveTo(fx, y)
        ..lineTo(fx + step, y)
        ..lineTo(fx + step / 2, y + size.height * 0.05)
        ..close();
      canvas.drawPath(flag, Paint()..color = _kBunting[i % _kBunting.length]);
    }
  }

  @override
  bool shouldRepaint(_ParkPainter old) => false;
}
