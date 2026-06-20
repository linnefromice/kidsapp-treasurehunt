part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene06: さばく
// ──────────────────────────────────────────
class _DesertPainter extends CustomPainter {
  const _DesertPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Warm desert sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55)),
    );

    // Sand
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6C56B), Color(0xFFE0A23E)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.55,
                size.width,
                size.height * 0.45,
              ),
            ),
    );

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.14),
      size.width * 0.06,
      Paint()..color = const Color(0xFFFFB300),
    );

    // Rolling dunes (lighter ridges across the sand)
    _drawDune(canvas, size, 0.58, const Color(0xFFEFB95B));
    _drawDune(canvas, size, 0.70, const Color(0xFFE8AC47));
    _drawDune(canvas, size, 0.83, const Color(0xFFDB9A33));

    // Cacti
    _drawCactus(canvas, size, 0.18, 0.74, 0.10);
    _drawCactus(canvas, size, 0.82, 0.68, 0.12);
    _drawCactus(canvas, size, 0.50, 0.82, 0.08);
  }

  void _drawDune(Canvas canvas, Size size, double topY, Color color) {
    final y = topY * size.height;
    final path = Path()..moveTo(0, y);
    final segW = size.width / 3;
    for (int i = 0; i < 3; i++) {
      path.quadraticBezierTo(
        (i + 0.5) * segW,
        y - size.height * 0.05,
        (i + 1.0) * segW,
        y,
      );
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCactus(Canvas canvas, Size size, double cx, double cy, double h) {
    final x = cx * size.width;
    final y = cy * size.height;
    final height = h * size.height;
    final w = height * 0.26;
    const green = Color(0xFF2E7D32);
    final paint = Paint()..color = green;
    // Main stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w / 2, y - height, w, height),
        Radius.circular(w / 2),
      ),
      paint,
    );
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w * 1.4, y - height * 0.65, w * 0.7, height * 0.30),
        Radius.circular(w * 0.35),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - w * 1.1, y - height * 0.75, w * 0.55, height * 0.32),
        Radius.circular(w * 0.3),
      ),
      paint,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.7, y - height * 0.55, w * 0.7, height * 0.26),
        Radius.circular(w * 0.35),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.55, y - height * 0.66, w * 0.55, height * 0.30),
        Radius.circular(w * 0.3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DesertPainter old) => false;
}
