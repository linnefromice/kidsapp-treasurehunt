part of 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';

// ──────────────────────────────────────────
// scene04: 山
// ──────────────────────────────────────────
class _MountainPainter extends CustomPainter {
  const _MountainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C94D6), Color(0xFF90CBF9)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Far mountains (pale, snow-capped)
    _drawMountain(canvas, size, 0.20, 0.55, 0.30, const Color(0xFFB0C4DE));
    _drawMountain(canvas, size, 0.80, 0.50, 0.28, const Color(0xFFB0C4DE));

    // Snow caps on far mountains
    _drawSnowCap(canvas, size, 0.20, 0.55, 0.30);
    _drawSnowCap(canvas, size, 0.80, 0.50, 0.28);

    // Meadow
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.70, size.width, size.height * 0.30),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.70,
                size.width,
                size.height * 0.30,
              ),
            ),
    );

    // Near mountains (darker, front)
    _drawMountain(canvas, size, 0.00, 0.75, 0.28, const Color(0xFF4A7856));
    _drawMountain(canvas, size, 0.50, 0.68, 0.34, const Color(0xFF3E6B4A));
    _drawMountain(canvas, size, 1.00, 0.73, 0.26, const Color(0xFF4A7856));

    // Clouds
    _drawCloud(canvas, size, 0.25, 0.10);
    _drawCloud(canvas, size, 0.70, 0.07);

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.09),
      size.width * 0.052,
      Paint()..color = const Color(0xFFFDD835),
    );
  }

  void _drawMountain(
    Canvas canvas,
    Size size,
    double peakX,
    double peakY,
    double halfWidth,
    Color color,
  ) {
    final path = Path()
      ..moveTo(peakX * size.width, peakY * size.height)
      ..lineTo((peakX - halfWidth) * size.width, size.height)
      ..lineTo((peakX + halfWidth) * size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawSnowCap(
    Canvas canvas,
    Size size,
    double peakX,
    double peakY,
    double halfWidth,
  ) {
    final snowH = halfWidth * 0.28;
    final path = Path()
      ..moveTo(peakX * size.width, peakY * size.height)
      ..lineTo(
        (peakX - snowH) * size.width,
        (peakY + snowH * 0.9) * size.height,
      )
      ..lineTo(
        (peakX + snowH) * size.width,
        (peakY + snowH * 0.9) * size.height,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
  }

  void _drawCloud(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.048;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 1.1, y + r * 0.1), r * 0.80, paint);
    canvas.drawCircle(Offset(x - r * 1.0, y + r * 0.15), r * 0.72, paint);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.55), r * 0.78, paint);
  }

  @override
  bool shouldRepaint(_MountainPainter old) => false;
}
