import 'dart:math' as math;
import 'package:flutter/material.dart';

Widget sceneBackground(String sceneId) => switch (sceneId) {
  'scene01' => const _PaintedScene(painter: _ForestPainter()),
  'scene02' => const _PaintedScene(painter: _OceanPainter()),
  'scene03' => const _PaintedScene(painter: _CityPainter()),
  'scene04' => const _PaintedScene(painter: _MountainPainter()),
  'scene05' => const _PaintedScene(painter: _NightPainter()),
  _ => const ColoredBox(color: Color(0xFF87CEEB)),
};

class _PaintedScene extends StatelessWidget {
  const _PaintedScene({required this.painter});
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: painter, child: const SizedBox.expand());
}

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

// ──────────────────────────────────────────
// scene02: 海
// ──────────────────────────────────────────
class _OceanPainter extends CustomPainter {
  const _OceanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.50),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0277BD), Color(0xFF29B6F6)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.50)),
    );

    // Deep sea
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.50, size.width, size.height * 0.25),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0288D1), Color(0xFF01579B)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.50,
                size.width,
                size.height * 0.25,
              ),
            ),
    );

    // Sandy beach
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE082), Color(0xFFFFCC02)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.72,
                size.width,
                size.height * 0.28,
              ),
            ),
    );

    // Wave layer 1
    _drawWaveBand(canvas, size, 0.66, 0.76, const Color(0xFF4FC3F7), 7);
    // Wave layer 2
    _drawWaveBand(
      canvas,
      size,
      0.59,
      0.68,
      const Color(0xFF0288D1).withValues(alpha: 0.7),
      5,
    );

    // Sun
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.10),
      size.width * 0.06,
      Paint()..color = const Color(0xFFFDD835),
    );

    // Clouds
    _drawCloud(canvas, size, 0.40, 0.08);
    _drawCloud(canvas, size, 0.75, 0.12);

    // Seashell on beach (decorative)
    _drawShell(canvas, size, 0.15, 0.85);
    _drawShell(canvas, size, 0.72, 0.88);
  }

  void _drawWaveBand(
    Canvas canvas,
    Size size,
    double y1,
    double y2,
    Color color,
    int waveCount,
  ) {
    final path = Path();
    final topY = y1 * size.height;
    final botY = y2 * size.height;
    path.moveTo(0, topY);
    final segW = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      path.quadraticBezierTo(
        (i + 0.5) * segW,
        topY - 12,
        (i + 1.0) * segW,
        topY,
      );
    }
    path.lineTo(size.width, botY);
    path.lineTo(0, botY);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCloud(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.05;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r * 1.15, y + r * 0.1), r * 0.82, paint);
    canvas.drawCircle(Offset(x - r * 1.05, y + r * 0.15), r * 0.74, paint);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.52), r * 0.76, paint);
  }

  void _drawShell(Canvas canvas, Size size, double cx, double cy) {
    final x = cx * size.width;
    final y = cy * size.height;
    final r = size.width * 0.022;
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()..color = const Color(0xFFFFAB91),
    );
    canvas.drawCircle(
      Offset(x, y),
      r * 0.55,
      Paint()..color = const Color(0xFFFF7043),
    );
  }

  @override
  bool shouldRepaint(_OceanPainter old) => false;
}

// ──────────────────────────────────────────
// scene03: 夜の街
// ──────────────────────────────────────────
class _CityPainter extends CustomPainter {
  const _CityPainter();

  static const _kBuildings = [
    // [left, top, width, height] normalized
    [0.00, 0.38, 0.10, 0.44],
    [0.11, 0.50, 0.08, 0.32],
    [0.20, 0.28, 0.13, 0.54],
    [0.34, 0.48, 0.09, 0.34],
    [0.44, 0.33, 0.11, 0.49],
    [0.56, 0.24, 0.10, 0.58],
    [0.67, 0.42, 0.10, 0.40],
    [0.78, 0.30, 0.11, 0.52],
    [0.90, 0.46, 0.10, 0.36],
  ];

  static const List<List<double>> _kStars = [
    [0.08, 0.06],
    [0.22, 0.10],
    [0.38, 0.05],
    [0.52, 0.09],
    [0.68, 0.04],
    [0.80, 0.11],
    [0.93, 0.07],
    [0.15, 0.18],
    [0.48, 0.16],
    [0.75, 0.19],
    [0.90, 0.22],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Night-to-dusk sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B4B),
            Color(0xFF3949AB),
            Color(0xFFE64A19),
            Color(0xFFFF8F00),
          ],
          stops: [0.0, 0.45, 0.72, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final s in _kStars) {
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        2.0,
        starPaint,
      );
    }

    // Moon
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.13),
      size.width * 0.04,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    // Moon crescent mask
    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.11),
      size.width * 0.034,
      Paint()..color = const Color(0xFF1A237E),
    );

    // Road
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.84, size.width, size.height * 0.16),
      Paint()..color = const Color(0xFF263238),
    );
    // Road center line
    final linePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.7)
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(
        Offset(x, size.height * 0.921),
        Offset(x + size.width / 16, size.height * 0.921),
        linePaint,
      );
    }

    // Buildings (silhouettes)
    for (final b in _kBuildings) {
      _drawBuilding(canvas, size, b[0], b[1], b[2], b[3]);
    }
  }

  void _drawBuilding(
    Canvas canvas,
    Size size,
    double l,
    double t,
    double w,
    double h,
  ) {
    final rect = Rect.fromLTWH(
      l * size.width,
      t * size.height,
      w * size.width,
      h * size.height,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0A0E2A));

    // Windows
    final winW = w * size.width * 0.18;
    final winH = h * size.height * 0.08;
    const cols = 2;
    final rows = math.max(2, (h * 10).floor());
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final lit = (row + col) % 3 != 0;
        final wx =
            rect.left + col * (w * size.width * 0.38) + w * size.width * 0.15;
        final wy =
            rect.top + row * (h * size.height * 0.18) + h * size.height * 0.08;
        canvas.drawRect(
          Rect.fromLTWH(wx, wy, winW, winH),
          Paint()
            ..color = lit
                ? Colors.yellow.withValues(alpha: 0.75)
                : Colors.blueGrey.shade900.withValues(alpha: 0.4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) => false;
}

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

// ──────────────────────────────────────────
// scene05: 夜の野原
// ──────────────────────────────────────────
class _NightPainter extends CustomPainter {
  const _NightPainter();

  static const List<List<double>> _kStars = [
    [0.06, 0.05],
    [0.18, 0.08],
    [0.30, 0.04],
    [0.42, 0.09],
    [0.55, 0.03],
    [0.67, 0.07],
    [0.78, 0.05],
    [0.90, 0.10],
    [0.12, 0.17],
    [0.35, 0.14],
    [0.58, 0.18],
    [0.82, 0.15],
    [0.05, 0.28],
    [0.25, 0.23],
    [0.47, 0.26],
    [0.72, 0.21],
    [0.94, 0.25],
    [0.15, 0.32],
    [0.60, 0.30],
    [0.88, 0.34],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Night sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E2A),
            Color(0xFF1A237E),
            Color(0xFF283593),
            Color(0xFF1B5E20),
          ],
          stops: [0.0, 0.50, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    for (final s in _kStars) {
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        2.2,
        starPaint,
      );
    }

    // Full moon
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.055,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    // Moon glow
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.075,
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.20),
    );

    // Ground (dark meadow)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF0D3B14)],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.68,
                size.width,
                size.height * 0.32,
              ),
            ),
    );

    // Fireflies (small glowing dots)
    final firefly = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: 0.80);
    final fireflyGlow = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: 0.25);
    for (final pos in [
      [0.28, 0.55],
      [0.45, 0.62],
      [0.62, 0.50],
      [0.75, 0.58],
      [0.15, 0.60],
      [0.87, 0.53],
    ]) {
      final fx = pos[0] * size.width;
      final fy = pos[1] * size.height;
      canvas.drawCircle(Offset(fx, fy), 5.0, fireflyGlow);
      canvas.drawCircle(Offset(fx, fy), 2.5, firefly);
    }

    // Silhouette trees at horizon
    _drawSilhouetteTree(canvas, size, 0.05, 0.70, 0.07);
    _drawSilhouetteTree(canvas, size, 0.22, 0.68, 0.09);
    _drawSilhouetteTree(canvas, size, 0.78, 0.69, 0.08);
    _drawSilhouetteTree(canvas, size, 0.95, 0.71, 0.07);
  }

  void _drawSilhouetteTree(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double r,
  ) {
    final x = cx * size.width;
    final y = cy * size.height;
    final radius = r * size.width;
    canvas.drawCircle(
      Offset(x, y - radius * 0.2),
      radius,
      Paint()..color = const Color(0xFF0A1F0A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y + radius * 0.5),
          width: radius * 0.25,
          height: radius * 0.8,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF0A1F0A),
    );
  }

  @override
  bool shouldRepaint(_NightPainter old) => false;
}
