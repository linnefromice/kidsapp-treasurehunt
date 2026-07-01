part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene21: スーパー（陳列棚のならぶ店内）
// ──────────────────────────────────────────
class _SupermarketPainter extends CustomPainter {
  const _SupermarketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // 店内のかべ（明るい）
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
        ).createShader(full),
    );
    // 天井のライン
    final ceil = Paint()
      ..color = const Color(0xFFBBDEFB)
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(0, size.height * 0.10),
      Offset(size.width, size.height * 0.10),
      ceil,
    );
    // ゆか
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      Paint()..color = const Color(0xFFECEFF1),
    );
    // 陳列棚（3 本）＋商品の色帯
    const shelfXs = [0.06, 0.40, 0.74];
    for (final sx in shelfXs) {
      _shelf(canvas, size, sx);
    }
  }

  void _shelf(Canvas canvas, Size size, double lx) {
    final rect = Rect.fromLTWH(
      lx * size.width,
      size.height * 0.24,
      size.width * 0.20,
      size.height * 0.58,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFFCFD8DC));
    // 棚板と、そこに並ぶ商品の色帯
    const rowColors = [
      Color(0xFFFFCC80),
      Color(0xFFA5D6A7),
      Color(0xFF90CAF9),
      Color(0xFFF48FB1),
    ];
    final board = Paint()..color = const Color(0xFF90A4AE);
    for (var i = 0; i < 4; i++) {
      final y = rect.top + rect.height * (i / 4);
      // 商品の色帯
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + 3,
          y + rect.height * 0.03,
          rect.width - 6,
          rect.height * 0.14,
        ),
        Paint()..color = rowColors[i].withValues(alpha: 0.85),
      );
      // 棚板
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          y + rect.height * 0.20,
          rect.width,
          rect.height * 0.03,
        ),
        board,
      );
    }
  }

  @override
  bool shouldRepaint(_SupermarketPainter old) => false;
}
