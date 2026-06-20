import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient.dart';

/// シーン背景。静止画レイヤ（[_PaintedScene]）の上に環境アニメ層
/// （[sceneAmbient]）を重ねる。静止画はそのまま、その上で雲・光・雪などが緩く動く。
Widget sceneBackground(String sceneId) => Stack(
  fit: StackFit.expand,
  children: [_sceneBase(sceneId), sceneAmbient(sceneId)],
);

Widget _sceneBase(String sceneId) => switch (sceneId) {
  'scene01' => const _PaintedScene(painter: _ForestPainter()),
  'scene02' => const _PaintedScene(painter: _OceanPainter()),
  'scene03' => const _PaintedScene(painter: _CityPainter()),
  'scene04' => const _PaintedScene(painter: _MountainPainter()),
  'scene05' => const _PaintedScene(painter: _NightPainter()),
  'scene06' => const _PaintedScene(painter: _DesertPainter()),
  'scene07' => const _PaintedScene(painter: _SpacePainter()),
  'scene08' => const _PaintedScene(painter: _UnderseaPainter()),
  'scene09' => const _PaintedScene(painter: _SnowPainter()),
  'scene10' => const _PaintedScene(painter: _FlowerFieldPainter()),
  'scene11' => const _PaintedScene(painter: _RainbowHillsPainter()),
  'scene12' => const _PaintedScene(painter: _CastlePainter()),
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

// ──────────────────────────────────────────
// scene08: うみのなか
// ──────────────────────────────────────────
class _UnderseaPainter extends CustomPainter {
  const _UnderseaPainter();

  static const List<List<double>> _kBubbles = [
    [0.12, 0.20, 6],
    [0.20, 0.34, 4],
    [0.38, 0.12, 5],
    [0.52, 0.28, 7],
    [0.64, 0.16, 4],
    [0.78, 0.30, 6],
    [0.88, 0.18, 5],
    [0.30, 0.50, 5],
    [0.70, 0.52, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Fully submerged: teal near the surface to deep navy below
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF26C6DA),
            Color(0xFF0097A7),
            Color(0xFF01579B),
            Color(0xFF002F6C),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Light rays from the surface
    final rayPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (final cx in [0.25, 0.55, 0.80]) {
      final x = cx * size.width;
      final ray = Path()
        ..moveTo(x, 0)
        ..lineTo(x + size.width * 0.10, 0)
        ..lineTo(x + size.width * 0.02, size.height * 0.75)
        ..lineTo(x - size.width * 0.06, size.height * 0.75)
        ..close();
      canvas.drawPath(ray, rayPaint);
    }

    // Sandy sea floor
    final floorTop = size.height * 0.82;
    final floor = Path()
      ..moveTo(0, floorTop)
      ..quadraticBezierTo(
        size.width * 0.30,
        floorTop - size.height * 0.04,
        size.width * 0.55,
        floorTop,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        floorTop + size.height * 0.04,
        size.width,
        floorTop - size.height * 0.01,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFFE0C27C));

    // Seaweed on the floor
    // baseY pinned to the floor top (0.82) so stems grow from the surface.
    _drawSeaweed(canvas, size, 0.10, 0.82, 0.16);
    _drawSeaweed(canvas, size, 0.16, 0.82, 0.12);
    _drawSeaweed(canvas, size, 0.86, 0.82, 0.18);
    _drawSeaweed(canvas, size, 0.92, 0.82, 0.13);

    // Bubbles
    for (final b in _kBubbles) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(b[0] * size.width, b[1] * size.height),
        b[2].toDouble(),
        paint,
      );
    }
  }

  void _drawSeaweed(
    Canvas canvas,
    Size size,
    double cx,
    double baseY,
    double h,
  ) {
    final x = cx * size.width;
    final by = baseY * size.height;
    final height = h * size.height;
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(x, by)
      ..quadraticBezierTo(
        x - size.width * 0.03,
        by - height * 0.4,
        x,
        by - height * 0.6,
      )
      ..quadraticBezierTo(
        x + size.width * 0.03,
        by - height * 0.8,
        x,
        by - height,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_UnderseaPainter old) => false;
}

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
    const spots = [
      [0.12, 0.72, 0.030, 0xFFEF5350],
      [0.30, 0.84, 0.034, 0xFFFFEE58],
      [0.50, 0.70, 0.028, 0xFFAB47BC],
      [0.68, 0.86, 0.034, 0xFFFF7043],
      [0.86, 0.74, 0.030, 0xFFEC407A],
      [0.20, 0.94, 0.030, 0xFF7E57C2],
      [0.78, 0.94, 0.030, 0xFFFFCA28],
    ];
    for (final s in spots) {
      _drawFlower(
        canvas,
        Offset(size.width * (s[0] as double), size.height * (s[1] as double)),
        size.width * (s[2] as double),
        Color(s[3] as int),
      );
    }
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

// ──────────────────────────────────────────
// scene12: おしろ
// ──────────────────────────────────────────
class _CastlePainter extends CustomPainter {
  const _CastlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.70),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E57C2), Color(0xFFB39DDB)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.70)),
    );

    // Grassy ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.70, size.width, size.height * 0.30),
      Paint()..color = const Color(0xFF7CB342),
    );

    // Castle body
    final body = const Color(0xFFECEFF1);
    final bodyPaint = Paint()..color = body;
    final castleRect = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.34,
      size.width * 0.40,
      size.height * 0.36,
    );
    canvas.drawRect(castleRect, bodyPaint);

    // Three towers with battlements
    final towerW = size.width * 0.10;
    for (final cx in [0.28, 0.50, 0.72]) {
      final left = size.width * cx - towerW / 2;
      final top = size.height * 0.26;
      canvas.drawRect(
        Rect.fromLTWH(left, top, towerW, size.height * 0.44),
        bodyPaint,
      );
      // Battlement teeth
      final tooth = towerW / 3;
      for (int i = 0; i < 3; i++) {
        if (i.isEven) {
          canvas.drawRect(
            Rect.fromLTWH(left + i * tooth, top - tooth, tooth, tooth),
            bodyPaint,
          );
        }
      }
      // Conical roof on the side towers
      if (cx != 0.50) {
        final roof = Path()
          ..moveTo(size.width * cx, top - size.height * 0.10)
          ..lineTo(left - tooth * 0.3, top)
          ..lineTo(left + towerW + tooth * 0.3, top)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFFE53935));
      }
    }

    // Gate
    final gate = Path()
      ..moveTo(size.width * 0.45, size.height * 0.70)
      ..lineTo(size.width * 0.45, size.height * 0.52)
      ..arcToPoint(
        Offset(size.width * 0.55, size.height * 0.52),
        radius: Radius.circular(size.width * 0.05),
      )
      ..lineTo(size.width * 0.55, size.height * 0.70)
      ..close();
    canvas.drawPath(gate, Paint()..color = const Color(0xFF5D4037));

    // Flag on the central tower
    final poleX = size.width * 0.50;
    final poleTop = size.height * 0.10;
    canvas.drawLine(
      Offset(poleX, poleTop),
      Offset(poleX, size.height * 0.18),
      Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 2,
    );
    final flag = Path()
      ..moveTo(poleX, poleTop)
      ..lineTo(poleX + size.width * 0.07, poleTop + size.height * 0.025)
      ..lineTo(poleX, poleTop + size.height * 0.05)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFD54F));
  }

  @override
  bool shouldRepaint(_CastlePainter old) => false;
}
