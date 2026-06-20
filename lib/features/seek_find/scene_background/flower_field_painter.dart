part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene10: はなばたけ
// ──────────────────────────────────────────
class _FlowerFieldPainter extends CustomPainter {
  const _FlowerFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Soft spring sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55)),
    );

    // Grassy meadow
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
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
      Offset(size.width * 0.82, size.height * 0.16),
      size.width * 0.05,
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Scattered flowers across the meadow
    final w = size.width;
    final h = size.height;
    _drawFlower(
      canvas,
      Offset(w * 0.12, h * 0.72),
      w * 0.030,
      const Color(0xFFEF5350),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.30, h * 0.84),
      w * 0.034,
      const Color(0xFFFFEE58),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.50, h * 0.70),
      w * 0.028,
      const Color(0xFFAB47BC),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.68, h * 0.86),
      w * 0.034,
      const Color(0xFFFF7043),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.86, h * 0.74),
      w * 0.030,
      const Color(0xFFEC407A),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.20, h * 0.94),
      w * 0.030,
      const Color(0xFF7E57C2),
    );
    _drawFlower(
      canvas,
      Offset(w * 0.78, h * 0.94),
      w * 0.030,
      const Color(0xFFFFCA28),
    );
  }

  void _drawFlower(Canvas canvas, Offset center, double r, Color color) {
    final petal = Paint()..color = color;
    for (int i = 0; i < 5; i++) {
      final a = i * (2 * math.pi / 5);
      canvas.drawCircle(
        center + Offset(math.cos(a) * r, math.sin(a) * r),
        r * 0.7,
        petal,
      );
    }
    canvas.drawCircle(
      center,
      r * 0.7,
      Paint()..color = const Color(0xFFFFF59D),
    );
  }

  @override
  bool shouldRepaint(_FlowerFieldPainter old) => false;
}
