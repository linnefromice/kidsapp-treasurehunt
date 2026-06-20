part of '../scene_background.dart';

// ──────────────────────────────────────────
// scene09: ゆきやま
// ──────────────────────────────────────────
class _SnowPainter extends CustomPainter {
  const _SnowPainter();

  static const List<List<double>> _kFlakes = [
    [0.08, 0.10],
    [0.18, 0.22],
    [0.28, 0.08],
    [0.40, 0.18],
    [0.52, 0.06],
    [0.62, 0.20],
    [0.72, 0.10],
    [0.84, 0.24],
    [0.92, 0.12],
    [0.14, 0.40],
    [0.34, 0.46],
    [0.50, 0.38],
    [0.68, 0.48],
    [0.88, 0.42],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Pale winter sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Pale sun
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.14),
      size.width * 0.05,
      Paint()..color = const Color(0xFFFFF59D),
    );

    // Snowy mountains. Outer bases intentionally bleed past the canvas edges
    // (clipped by widget bounds) for a full-width silhouette on landscape.
    _drawSnowMountain(canvas, size, 0.22, 0.45, 0.32);
    _drawSnowMountain(canvas, size, 0.74, 0.40, 0.34);
    _drawSnowMountain(canvas, size, 0.50, 0.52, 0.28);

    // Snow field
    final fieldTop = size.height * 0.72;
    final field = Path()
      ..moveTo(0, fieldTop)
      ..quadraticBezierTo(
        size.width * 0.5,
        fieldTop - size.height * 0.04,
        size.width,
        fieldTop,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(field, Paint()..color = Colors.white);

    // Snowy pine trees
    _drawSnowyPine(canvas, size, 0.14, 0.74, 0.13);
    _drawSnowyPine(canvas, size, 0.60, 0.78, 0.15);
    _drawSnowyPine(canvas, size, 0.88, 0.73, 0.12);

    // Falling snowflakes
    final flake = Paint()..color = Colors.white.withValues(alpha: 0.95);
    for (var i = 0; i < _kFlakes.length; i++) {
      final f = _kFlakes[i];
      canvas.drawCircle(
        Offset(f[0] * size.width, f[1] * size.height),
        i.isEven ? 3.0 : 2.0,
        flake,
      );
    }
  }

  void _drawSnowMountain(
    Canvas canvas,
    Size size,
    double peakX,
    double peakY,
    double halfWidth,
  ) {
    final px = peakX * size.width;
    final py = peakY * size.height;
    final body = Path()
      ..moveTo(px, py)
      ..lineTo((peakX - halfWidth) * size.width, size.height)
      ..lineTo((peakX + halfWidth) * size.width, size.height)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF90A4AE));

    // Snow cap
    final capH = halfWidth * 0.30;
    final cap = Path()
      ..moveTo(px, py)
      ..lineTo((peakX - capH) * size.width, (peakY + capH * 0.9) * size.height)
      ..quadraticBezierTo(
        px,
        (peakY + capH * 0.5) * size.height,
        (peakX + capH) * size.width,
        (peakY + capH * 0.9) * size.height,
      )
      ..close();
    canvas.drawPath(cap, Paint()..color = Colors.white);
  }

  void _drawSnowyPine(
    Canvas canvas,
    Size size,
    double cx,
    double baseY,
    double h,
  ) {
    final x = cx * size.width;
    final by = baseY * size.height;
    final height = h * size.height;
    final halfW = height * 0.32;
    const green = Color(0xFF2E7D32);

    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, by + height * 0.05),
        width: halfW * 0.3,
        height: height * 0.18,
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Three foliage tiers, each with a white snow cap on top
    for (var i = 0; i < 3; i++) {
      final tierTop = by - height * (1.0 - i * 0.28);
      // 0.56 (not 0.55) keeps every tier bottom strictly above the base point.
      final tierBot = by - height * (0.56 - i * 0.28);
      final w = halfW * (0.55 + i * 0.22);
      final tier = Path()
        ..moveTo(x, tierTop)
        ..lineTo(x - w, tierBot)
        ..lineTo(x + w, tierBot)
        ..close();
      canvas.drawPath(tier, Paint()..color = green);
      // Snow on the tier
      final snow = Path()
        ..moveTo(x, tierTop)
        ..lineTo(x - w * 0.5, tierTop + (tierBot - tierTop) * 0.5)
        ..quadraticBezierTo(
          x,
          tierTop + (tierBot - tierTop) * 0.3,
          x + w * 0.5,
          tierTop + (tierBot - tierTop) * 0.5,
        )
        ..close();
      canvas.drawPath(
        snow,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => false;
}
