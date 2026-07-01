part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene20: こどもべや（ラグ・棚・窓のある部屋の中）
// ──────────────────────────────────────────
class _ToyRoomPainter extends CustomPainter {
  const _ToyRoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // かべ（やわらかいクリーム色）
    canvas.drawRect(full, Paint()..color = const Color(0xFFFFF8E1));
    // ゆか
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.26),
      Paint()..color = const Color(0xFFD7A86E),
    );
    // フローリングの目地
    final seam = Paint()
      ..color = const Color(0xFFB07C4A)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += size.width / 10) {
      canvas.drawLine(
        Offset(x, size.height * 0.74),
        Offset(x, size.height),
        seam,
      );
    }
    // まるいラグ
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.86),
        width: size.width * 0.5,
        height: size.height * 0.2,
      ),
      Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.8),
    );
    // 窓（左上）
    final win = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.10,
      size.width * 0.26,
      size.height * 0.28,
    );
    canvas.drawRect(win, Paint()..color = const Color(0xFFB3E5FC));
    canvas.drawRect(
      win,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFFFFFFFF),
    );
    canvas.drawLine(
      win.topCenter,
      win.bottomCenter,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      win.centerLeft,
      win.centerRight,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 5,
    );
    // おもちゃ棚（右）
    final shelf = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.16,
      size.width * 0.26,
      size.height * 0.54,
    );
    canvas.drawRect(shelf, Paint()..color = const Color(0xFFA1887F));
    final board = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 4;
    for (var i = 1; i < 3; i++) {
      final y = shelf.top + shelf.height * (i / 3);
      canvas.drawLine(Offset(shelf.left, y), Offset(shelf.right, y), board);
    }
  }

  @override
  bool shouldRepaint(_ToyRoomPainter old) => false;
}
