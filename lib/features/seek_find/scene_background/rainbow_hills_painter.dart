part of 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';

// ──────────────────────────────────────────
// scene11: にじのおか
// ──────────────────────────────────────────
class _RainbowHillsPainter extends CustomPainter {
  const _RainbowHillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Clear sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        ).createShader(Offset.zero & size),
    );

    // Rainbow arc, painted from outer to inner band
    const bands = [
      0xFFEF5350,
      0xFFFFA726,
      0xFFFFEE58,
      0xFF66BB6A,
      0xFF42A5F5,
      0xFF7E57C2,
    ];
    final center = Offset(size.width * 0.5, size.height * 0.92);
    final outer = size.width * 0.46;
    final stroke = outer * 0.07;
    for (int i = 0; i < bands.length; i++) {
      final radius = outer - i * stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Color(bands[i])
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Rolling green hills in the foreground
    _drawHill(canvas, size, 0.78, const Color(0xFF81C784));
    _drawHill(canvas, size, 0.88, const Color(0xFF66BB6A));

    // A couple of soft clouds
    _drawCloud(
      canvas,
      Offset(size.width * 0.18, size.height * 0.20),
      size.width * 0.05,
    );
    _drawCloud(
      canvas,
      Offset(size.width * 0.80, size.height * 0.26),
      size.width * 0.06,
    );
  }

  void _drawHill(Canvas canvas, Size size, double topY, Color color) {
    final y = topY * size.height;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, y)
      ..quadraticBezierTo(
        size.width * 0.5,
        y - size.height * 0.12,
        size.width,
        y,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCloud(Canvas canvas, Offset center, double r) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center + Offset(r * 0.9, r * 0.1), r * 0.8, paint);
    canvas.drawCircle(center - Offset(r * 0.9, -r * 0.1), r * 0.8, paint);
  }

  @override
  bool shouldRepaint(_RainbowHillsPainter old) => false;
}
