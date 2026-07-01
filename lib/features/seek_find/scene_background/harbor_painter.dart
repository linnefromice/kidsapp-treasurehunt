part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene19: みなと（桟橋と停泊する船と灯台）
// ──────────────────────────────────────────
class _HarborPainter extends CustomPainter {
  const _HarborPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // 空
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC)],
          stops: [0.0, 1.0],
        ).createShader(full),
    );
    // 海
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.58, size.width, size.height * 0.42),
      Paint()..color = const Color(0xFF039BE5),
    );
    // 波のさざなみ
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var r = 0; r < 4; r++) {
      final y = size.height * (0.66 + r * 0.07);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += size.width / 8) {
        path.relativeQuadraticBezierTo(size.width / 16, -6, size.width / 8, 0);
      }
      canvas.drawPath(path, wave);
    }
    // 桟橋（木の板）
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.56, size.width, size.height * 0.06),
      Paint()..color = const Color(0xFF8D6E63),
    );
    final plank = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += size.width / 16) {
      canvas.drawLine(
        Offset(x, size.height * 0.56),
        Offset(x, size.height * 0.62),
        plank,
      );
    }
    // 灯台（右手前）
    final lx = size.width * 0.88;
    final ltop = size.height * 0.30;
    final lbot = size.height * 0.56;
    final tower = Path()
      ..moveTo(lx - size.width * 0.035, lbot)
      ..lineTo(lx - size.width * 0.022, ltop)
      ..lineTo(lx + size.width * 0.022, ltop)
      ..lineTo(lx + size.width * 0.035, lbot)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFFFFF3E0));
    // 灯台の赤い帯
    final band = Paint()..color = const Color(0xFFE53935);
    for (var i = 0; i < 3; i++) {
      final y = ltop + (lbot - ltop) * (0.2 + i * 0.28);
      canvas.drawRect(
        Rect.fromLTWH(
          lx - size.width * 0.03,
          y,
          size.width * 0.06,
          (lbot - ltop) * 0.12,
        ),
        band,
      );
    }
    // 灯（トップ）
    canvas.drawCircle(
      Offset(lx, ltop - size.height * 0.02),
      size.width * 0.02,
      Paint()..color = const Color(0xFFFFF176),
    );
  }

  @override
  bool shouldRepaint(_HarborPainter old) => false;
}
