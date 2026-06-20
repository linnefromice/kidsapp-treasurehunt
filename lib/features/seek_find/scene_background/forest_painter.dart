part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene01: 森
// ──────────────────────────────────────────
class _ForestPainter extends CustomPainter {
  const _ForestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.60),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64B5F6), Color(0xFF90CAF9)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.60)),
    );

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.60, size.width, size.height * 0.40),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.60,
                size.width,
                size.height * 0.40,
              ),
            ),
    );

    // Bushes on ground
    _drawBush(canvas, size, 0.05, 0.64, 0.06);
    _drawBush(canvas, size, 0.50, 0.66, 0.05);
    _drawBush(canvas, size, 0.88, 0.63, 0.06);

    // Trees (back row, smaller)
    _drawTree(canvas, size, 0.08, 0.48, 0.07, const Color(0xFF1B5E20));
    _drawTree(canvas, size, 0.92, 0.46, 0.07, const Color(0xFF1B5E20));

    // Trees (front row)
    _drawTree(canvas, size, 0.20, 0.52, 0.10, const Color(0xFF2E7D32));
    _drawTree(canvas, size, 0.42, 0.55, 0.085, const Color(0xFF388E3C));
    _drawTree(canvas, size, 0.63, 0.50, 0.11, const Color(0xFF2E7D32));
    _drawTree(canvas, size, 0.82, 0.53, 0.09, const Color(0xFF388E3C));

    // Clouds
    _drawCloud(canvas, size, 0.18, 0.10);
    _drawCloud(canvas, size, 0.65, 0.07);
    _drawCloud(canvas, size, 0.45, 0.18);

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.10),
      size.width * 0.055,
      Paint()..color = const Color(0xFFFDD835),
    );
  }

  void _drawTree(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
    Color foliageColor,
  ) {
    final x = cx * size.width;
    final y = cy * size.height;
    final radius = r * size.width;
    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y + radius * 0.8),
          width: radius * 0.28,
          height: radius * 0.90,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    // Shadow circle
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = foliageColor.withValues(alpha: 0.5),
    );
    // Main foliage
    canvas.drawCircle(
      Offset(x, y - radius * 0.1),
      radius * 0.90,
      Paint()..color = foliageColor,
    );
    // Highlight
    canvas.drawCircle(
      Offset(x - radius * 0.25, y - radius * 0.30),
      radius * 0.45,
      Paint()..color = foliageColor.withAlpha(200),
    );
  }

  void _drawBush(Canvas canvas, Size size, double cx, double cy, double r) {
    final x = cx * size.width;
    final y = cy * size.height;
    final radius = r * size.width;
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = const Color(0xFF1B5E20),
    );
    canvas.drawCircle(
      Offset(x + radius * 0.8, y),
      radius * 0.75,
      Paint()..color = const Color(0xFF2E7D32),
    );
    canvas.drawCircle(
      Offset(x - radius * 0.75, y),
      radius * 0.70,
      Paint()..color = const Color(0xFF2E7D32),
    );
  }

  void _drawCloud(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.048;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 1.1, y + r * 0.1), r * 0.80, paint);
    canvas.drawCircle(Offset(x - r * 1.0, y + r * 0.15), r * 0.72, paint);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.55), r * 0.78, paint);
  }

  @override
  bool shouldRepaint(_ForestPainter old) => false;
}
