part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene07: うちゅう
// ──────────────────────────────────────────
class _SpacePainter extends CustomPainter {
  const _SpacePainter();

  static const List<List<double>> _kStars = [
    [0.05, 0.06],
    [0.14, 0.14],
    [0.24, 0.04],
    [0.33, 0.20],
    [0.45, 0.08],
    [0.55, 0.16],
    [0.66, 0.05],
    [0.74, 0.13],
    [0.85, 0.07],
    [0.94, 0.18],
    [0.10, 0.40],
    [0.30, 0.52],
    [0.50, 0.46],
    [0.70, 0.60],
    [0.90, 0.44],
    [0.20, 0.72],
    [0.42, 0.80],
    [0.60, 0.74],
    [0.82, 0.84],
    [0.96, 0.66],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Deep space gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0033), Color(0xFF1A0A52), Color(0xFF311B92)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars (two sizes for depth)
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    for (var i = 0; i < _kStars.length; i++) {
      final s = _kStars[i];
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        i.isEven ? 2.6 : 1.6,
        starPaint,
      );
    }

    // Big planet with ring
    final planet = Offset(size.width * 0.80, size.height * 0.26);
    final pr = size.width * 0.10;
    canvas.drawCircle(planet, pr, Paint()..color = const Color(0xFFEF6C00));
    canvas.drawCircle(
      Offset(planet.dx - pr * 0.3, planet.dy - pr * 0.3),
      pr * 0.45,
      Paint()..color = const Color(0xFFFFB74D),
    );
    // Ring
    canvas.save();
    canvas.translate(planet.dx, planet.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: pr * 3.4, height: pr * 0.9),
      Paint()
        ..color = const Color(0xFFFFE0B2).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pr * 0.18,
    );
    canvas.restore();

    // Small moon
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.20),
      size.width * 0.04,
      Paint()..color = const Color(0xFFB0BEC5),
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.19),
      size.width * 0.012,
      Paint()..color = const Color(0xFF90A4AE),
    );

    // Crater ground at the bottom (a planet surface)
    final groundTop = size.height * 0.86;
    final ground = Path()
      ..moveTo(0, groundTop)
      ..quadraticBezierTo(
        size.width * 0.5,
        groundTop - size.height * 0.05,
        size.width,
        groundTop,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF4527A0));
  }

  @override
  bool shouldRepaint(_SpacePainter old) => false;
}
