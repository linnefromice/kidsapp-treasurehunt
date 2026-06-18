import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Returns a [CustomPainter] that renders a 2.5D treasure icon for item [id].
/// [found] = true switches to the golden highlight variant.
CustomPainter treasureIconPainter(String id, {required bool found}) =>
    switch (id) {
      'apple' => _ApplePainter(found: found),
      'duck' => _DuckPainter(found: found),
      'star' => _StarPainter(found: found),
      'ball' => _BallPainter(found: found),
      'flower' => _FlowerPainter(found: found),
      'heart' => _HeartPainter(found: found),
      'leaf' => _LeafPainter(found: found),
      'rabbit' => _RabbitPainter(found: found),
      'bug' => _BugPainter(found: found),
      'anchor' => _AnchorPainter(found: found),
      'swimmer' => _SwimmerPainter(found: found),
      'umbrella' => _UmbrellaPainter(found: found),
      'car' => _CarPainter(found: found),
      'key' => _KeyPainter(found: found),
      _ => _FallbackPainter(found: found),
    };

// ── Shared helpers ───────────────────────────────────────────────────────────

void _shadow(Canvas c, Offset center, double rx, double ry) {
  c.drawOval(
    Rect.fromCenter(
      center: Offset(center.dx + rx * 0.06, center.dy + ry * 0.92),
      width: rx * 1.5,
      height: ry * 0.14,
    ),
    Paint()..color = const Color(0x33000000),
  );
}

void _highlight(Canvas c, Offset o, double rx, double ry) {
  c.drawOval(
    Rect.fromCenter(center: o, width: rx, height: ry),
    Paint()..color = const Color(0x99FFFFFF),
  );
}

Paint _spherePaint(Rect b, Color bright, Color dark) => Paint()
  ..shader = RadialGradient(
    center: const Alignment(-0.35, -0.40),
    radius: 1.0,
    colors: [bright, dark],
  ).createShader(b);

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

// ── Apple ────────────────────────────────────────────────────────────────────

class _ApplePainter extends CustomPainter {
  _ApplePainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.55;
    final r = w * 0.38;
    final bc = Offset(cx, cy);
    final br = Rect.fromCircle(center: bc, radius: r);

    _shadow(canvas, bc, r, r);
    canvas.drawCircle(
      bc,
      r,
      _spherePaint(
        br,
        found ? const Color(0xFFFFE57F) : const Color(0xFFFF5252),
        found ? const Color(0xFFFF8F00) : const Color(0xFFB71C1C),
      ),
    );
    canvas.drawCircle(bc, r, _stroke(const Color(0x44000000), w * 0.02));

    // Stalk
    canvas.drawLine(
      Offset(cx, cy - r),
      Offset(cx + w * 0.06, cy - r - h * 0.10),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Leaf
    final leaf = Path()
      ..moveTo(cx + w * 0.03, cy - r - h * 0.03)
      ..quadraticBezierTo(
        cx + w * 0.20,
        cy - r - h * 0.14,
        cx + w * 0.13,
        cy - r + h * 0.02,
      )
      ..quadraticBezierTo(
        cx + w * 0.06,
        cy - r - h * 0.04,
        cx + w * 0.03,
        cy - r - h * 0.03,
      );
    canvas.drawPath(
      leaf,
      Paint()..color = found ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32),
    );

    _highlight(canvas, Offset(cx - r * 0.32, cy - r * 0.36), r * 0.42, r * 0.26);
  }

  @override
  bool shouldRepaint(covariant _ApplePainter old) => old.found != found;
}

// ── Duck ─────────────────────────────────────────────────────────────────────

class _DuckPainter extends CustomPainter {
  _DuckPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bright = found ? const Color(0xFFFFF176) : const Color(0xFFFFD740);
    final dark = found ? const Color(0xFFFFCC02) : const Color(0xFFFF8F00);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.89),
        width: w * 0.70,
        height: h * 0.10,
      ),
      Paint()..color = const Color(0x33000000),
    );

    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.63),
      width: w * 0.72,
      height: h * 0.50,
    );
    canvas.drawOval(bodyRect, _spherePaint(bodyRect, bright, dark));
    canvas.drawOval(bodyRect, _stroke(const Color(0x44000000), w * 0.02));

    final headCenter = Offset(w * 0.56, h * 0.32);
    final headRect = Rect.fromCircle(center: headCenter, radius: w * 0.27);
    canvas.drawCircle(headCenter, w * 0.27, _spherePaint(headRect, bright, dark));
    canvas.drawCircle(headCenter, w * 0.27, _stroke(const Color(0x44000000), w * 0.02));

    final beak = Path()
      ..moveTo(w * 0.80, h * 0.30)
      ..lineTo(w * 0.95, h * 0.315)
      ..lineTo(w * 0.80, h * 0.39)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF8F00));
    canvas.drawPath(beak, _stroke(const Color(0x66000000), w * 0.02));

    canvas.drawCircle(
      Offset(w * 0.66, h * 0.27),
      w * 0.055,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(w * 0.635, h * 0.252),
      w * 0.022,
      Paint()..color = Colors.white,
    );

    _highlight(canvas, Offset(w * 0.46, h * 0.25), w * 0.11, h * 0.07);
  }

  @override
  bool shouldRepaint(covariant _DuckPainter old) => old.found != found;
}

// ── Star ─────────────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  _StarPainter({required this.found});
  final bool found;

  static Path _starPath(Offset center, double outer, double inner) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * math.pi / 180;
      final r = i.isEven ? outer : inner;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w * 0.50, size.height * 0.52);
    final outer = w * 0.43;
    final inner = w * 0.18;

    _shadow(canvas, center, outer, outer);

    final path = _starPath(center, outer, inner);
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.0,
          colors: found
              ? [const Color(0xFFFFFFFF), const Color(0xFF76FF03)]
              : [const Color(0xFFFFF9C4), const Color(0xFFFF8F00)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      _stroke(
        found ? const Color(0xFF33691E) : const Color(0xFFBF360C),
        w * 0.03,
      ),
    );
    canvas.drawCircle(
      center,
      inner * 0.65,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    _highlight(
      canvas,
      Offset(center.dx - outer * 0.18, center.dy - outer * 0.44),
      outer * 0.28,
      outer * 0.16,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.found != found;
}

// ── Ball ─────────────────────────────────────────────────────────────────────

class _BallPainter extends CustomPainter {
  _BallPainter({required this.found});
  final bool found;

  static const _stripes = [
    Color(0xFFFF5252),
    Color(0xFFFFFFFF),
    Color(0xFF1565C0),
    Color(0xFFFFCA28),
    Color(0xFF43A047),
    Color(0xFFFF5252),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w * 0.50, size.height * 0.52);
    final r = w * 0.40;
    final rect = Rect.fromCircle(center: center, radius: r);

    _shadow(canvas, center, r, r);

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    final stripeW = r * 2 / _stripes.length;
    for (int i = 0; i < _stripes.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(center.dx - r + i * stripeW, center.dy - r, stripeW, r * 2),
        Paint()..color = _stripes[i],
      );
    }

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.black.withValues(alpha: 0.22),
          ],
        ).createShader(rect),
    );

    if (found) {
      canvas.drawCircle(center, r, Paint()..color = const Color(0x55FFD740));
    }

    canvas.restore();

    canvas.drawCircle(center, r, _stroke(const Color(0x55000000), w * 0.025));
    _highlight(
      canvas,
      Offset(center.dx - r * 0.30, center.dy - r * 0.36),
      r * 0.42,
      r * 0.27,
    );
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.found != found;
}

// ── Flower ───────────────────────────────────────────────────────────────────

class _FlowerPainter extends CustomPainter {
  _FlowerPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.52;
    final petalR = w * 0.22;
    final petalDist = w * 0.27;
    final petalBright = found ? const Color(0xFFE040FB) : const Color(0xFFEC407A);
    final petalDark = found ? const Color(0xFF6A1B9A) : const Color(0xFF880E4F);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + petalDist * 0.88),
        width: petalDist * 1.5,
        height: petalDist * 0.14,
      ),
      Paint()..color = const Color(0x33000000),
    );

    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * math.pi / 180;
      final pc = Offset(
        cx + petalDist * math.cos(angle),
        cy + petalDist * math.sin(angle),
      );
      final pr = Rect.fromCircle(center: pc, radius: petalR);
      canvas.drawCircle(pc, petalR, _spherePaint(pr, petalBright, petalDark));
      canvas.drawCircle(pc, petalR, _stroke(const Color(0x44000000), w * 0.02));
    }

    final cc = Offset(cx, cy);
    final cr = Rect.fromCircle(center: cc, radius: w * 0.20);
    canvas.drawCircle(
      cc,
      w * 0.20,
      _spherePaint(cr, const Color(0xFFFFF176), const Color(0xFFFF8F00)),
    );
    canvas.drawCircle(cc, w * 0.20, _stroke(const Color(0x44000000), w * 0.02));

    _highlight(
      canvas,
      Offset(cx - petalR * 0.50, cy - petalDist * 0.80),
      petalR * 0.44,
      petalR * 0.27,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) => old.found != found;
}

// ── Heart ────────────────────────────────────────────────────────────────────

class _HeartPainter extends CustomPainter {
  _HeartPainter({required this.found});
  final bool found;

  static Path _heartPath(double cx, double cy, double r) => Path()
    ..moveTo(cx, cy + r * 0.38)
    ..cubicTo(cx - r * 0.48, cy + r * 0.28, cx - r, cy + r * 0.02, cx - r, cy - r * 0.30)
    ..cubicTo(cx - r, cy - r * 0.80, cx - r * 0.30, cy - r * 0.80, cx, cy - r * 0.38)
    ..cubicTo(cx + r * 0.30, cy - r * 0.80, cx + r, cy - r * 0.80, cx + r, cy - r * 0.30)
    ..cubicTo(cx + r, cy + r * 0.02, cx + r * 0.48, cy + r * 0.28, cx, cy + r * 0.38)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w * 0.50;
    final cy = size.height * 0.52;
    final r = w * 0.38;

    _shadow(canvas, Offset(cx, cy), r, r);

    final path = _heartPath(cx, cy, r);
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 1.0,
          colors: found
              ? [const Color(0xFFFFFFFF), const Color(0xFF76FF03)]
              : [const Color(0xFFFF80AB), const Color(0xFFC62828)],
        ).createShader(bounds),
    );
    canvas.drawPath(path, _stroke(const Color(0x55000000), w * 0.03));
    _highlight(canvas, Offset(cx - r * 0.35, cy - r * 0.22), r * 0.30, r * 0.18);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => old.found != found;
}

// ── Leaf ─────────────────────────────────────────────────────────────────────

class _LeafPainter extends CustomPainter {
  _LeafPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.52;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + h * 0.37),
        width: w * 0.55,
        height: h * 0.07,
      ),
      Paint()..color = const Color(0x33000000),
    );

    final leaf = Path()
      ..moveTo(cx, cy - h * 0.35)
      ..quadraticBezierTo(cx + w * 0.40, cy, cx, cy + h * 0.35)
      ..quadraticBezierTo(cx - w * 0.40, cy, cx, cy - h * 0.35);

    final lb = leaf.getBounds();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: found
              ? [const Color(0xFFCCFF90), const Color(0xFF33691E)]
              : [const Color(0xFF81C784), const Color(0xFF1B5E20)],
        ).createShader(lb),
    );
    canvas.drawPath(leaf, _stroke(const Color(0x44000000), w * 0.025));

    canvas.drawLine(
      Offset(cx, cy - h * 0.33),
      Offset(cx, cy + h * 0.33),
      Paint()
        ..color = const Color(0x88000000)
        ..strokeWidth = w * 0.025,
    );

    _highlight(canvas, Offset(cx - w * 0.10, cy - h * 0.17), w * 0.13, h * 0.10);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) => old.found != found;
}

// ── Rabbit ───────────────────────────────────────────────────────────────────

class _RabbitPainter extends CustomPainter {
  _RabbitPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final faceCenter = Offset(w * 0.50, h * 0.58);
    final faceR = w * 0.30;
    final bodyColor = found ? const Color(0xFFF3E5F5) : Colors.white;

    _shadow(canvas, faceCenter, faceR, faceR);

    for (final side in [-1.0, 1.0]) {
      final ec = Offset(w * (0.5 + side * 0.15), h * 0.25);
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: w * 0.18, height: h * 0.35),
        Paint()..color = bodyColor,
      );
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: w * 0.18, height: h * 0.35),
        _stroke(const Color(0x44000000), w * 0.02),
      );
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: w * 0.10, height: h * 0.26),
        Paint()..color = const Color(0xFFFFCDD2),
      );
    }

    final faceRect = Rect.fromCircle(center: faceCenter, radius: faceR);
    canvas.drawCircle(
      faceCenter,
      faceR,
      _spherePaint(faceRect, bodyColor, const Color(0xFFE8EAF6)),
    );
    canvas.drawCircle(faceCenter, faceR, _stroke(const Color(0x44000000), w * 0.025));

    for (final side in [-1.0, 1.0]) {
      final ec = Offset(w * (0.5 + side * 0.13), h * 0.53);
      canvas.drawCircle(ec, w * 0.050, Paint()..color = const Color(0xFF1A237E));
      canvas.drawCircle(
        Offset(ec.dx - w * 0.018, ec.dy - h * 0.015),
        w * 0.018,
        Paint()..color = Colors.white,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.63),
        width: w * 0.10,
        height: h * 0.06,
      ),
      Paint()..color = const Color(0xFFFF80AB),
    );

    _highlight(canvas, Offset(w * 0.40, h * 0.50), w * 0.10, h * 0.07);
  }

  @override
  bool shouldRepaint(covariant _RabbitPainter old) => old.found != found;
}

// ── Bug (butterfly) ──────────────────────────────────────────────────────────

class _BugPainter extends CustomPainter {
  _BugPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.50;
    final wBright = found ? const Color(0xFF76FF03) : const Color(0xFFFF6D00);
    final wDark = found ? const Color(0xFF33691E) : const Color(0xFFBF360C);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + h * 0.32),
        width: w * 0.28,
        height: h * 0.08,
      ),
      Paint()..color = const Color(0x33000000),
    );

    for (final side in [-1.0, 1.0]) {
      final wc = Offset(cx + side * w * 0.30, cy - h * 0.12);
      final wr = Rect.fromCenter(center: wc, width: w * 0.50, height: h * 0.40);
      canvas.drawOval(wr, _spherePaint(wr, wBright, wDark));
      canvas.drawOval(wr, _stroke(const Color(0x66000000), w * 0.02));
      canvas.drawCircle(
        wc,
        w * 0.08,
        Paint()..color = Colors.black.withValues(alpha: 0.28),
      );
    }

    for (final side in [-1.0, 1.0]) {
      final wc = Offset(cx + side * w * 0.24, cy + h * 0.18);
      final wr = Rect.fromCenter(center: wc, width: w * 0.34, height: h * 0.27);
      canvas.drawOval(wr, _spherePaint(wr, wBright, wDark));
      canvas.drawOval(wr, _stroke(const Color(0x66000000), w * 0.02));
    }

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.04),
      width: w * 0.15,
      height: h * 0.52,
    );
    canvas.drawOval(bodyRect, _spherePaint(bodyRect, Colors.black54, Colors.black87));

    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(cx, cy - h * 0.22),
        Offset(cx + side * w * 0.22, cy - h * 0.42),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(cx + side * w * 0.22, cy - h * 0.42),
        w * 0.035,
        Paint()..color = Colors.black87,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BugPainter old) => old.found != found;
}

// ── Anchor ───────────────────────────────────────────────────────────────────

class _AnchorPainter extends CustomPainter {
  _AnchorPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final color = found ? const Color(0xFF76FF03) : const Color(0xFF37474F);
    final thick = Paint()
      ..color = color
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.93),
        width: w * 0.50,
        height: h * 0.08,
      ),
      Paint()..color = const Color(0x33000000),
    );

    // Ring at top
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, h * 0.12), radius: w * 0.10),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08,
    );

    // Rod
    canvas.drawLine(Offset(cx, h * 0.20), Offset(cx, h * 0.82), thick);

    // Crossbar + ends
    canvas.drawLine(Offset(cx - w * 0.28, h * 0.30), Offset(cx + w * 0.28, h * 0.30), thick);
    canvas.drawCircle(Offset(cx - w * 0.28, h * 0.30), w * 0.055, Paint()..color = color);
    canvas.drawCircle(Offset(cx + w * 0.28, h * 0.30), w * 0.055, Paint()..color = color);

    // Bottom arc (upper semicircle of the flukes ring, drawn counterclockwise)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.67),
        width: w * 0.72,
        height: h * 0.40,
      ),
      math.pi,
      -math.pi,
      false,
      thick,
    );
    canvas.drawCircle(Offset(cx - w * 0.36, h * 0.67), w * 0.07, Paint()..color = color);
    canvas.drawCircle(Offset(cx + w * 0.36, h * 0.67), w * 0.07, Paint()..color = color);

    // Metallic sheen
    canvas.drawLine(
      Offset(cx + w * 0.03, h * 0.22),
      Offset(cx + w * 0.03, h * 0.80),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = w * 0.03,
    );
  }

  @override
  bool shouldRepaint(covariant _AnchorPainter old) => old.found != found;
}

// ── Swimmer ──────────────────────────────────────────────────────────────────

class _SwimmerPainter extends CustomPainter {
  _SwimmerPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final waveColor = found ? const Color(0xFF40C4FF) : const Color(0xFF1976D2);
    final skinColor = found ? const Color(0xFFFFFF8D) : const Color(0xFFFFE0B2);

    // Water
    final wavePath = Path()..moveTo(0, h * 0.60);
    for (int i = 0; i <= 4; i++) {
      wavePath.quadraticBezierTo(
        w * (i + 0.25) / 4,
        h * 0.54,
        w * (i + 0.5) / 4,
        h * 0.60,
      );
      wavePath.quadraticBezierTo(
        w * (i + 0.75) / 4,
        h * 0.66,
        w * (i + 1.0) / 4,
        h * 0.60,
      );
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.60, w, h * 0.40),
      Paint()..color = waveColor.withValues(alpha: 0.6),
    );
    canvas.drawPath(wavePath, Paint()..color = waveColor);

    final bodyPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.20, h * 0.52), Offset(w * 0.78, h * 0.42), bodyPaint);
    canvas.drawLine(Offset(w * 0.20, h * 0.52), Offset(w * 0.05, h * 0.36), bodyPaint);
    canvas.drawLine(Offset(w * 0.78, h * 0.42), Offset(w * 0.94, h * 0.26), bodyPaint);

    canvas.drawCircle(Offset(w * 0.78, h * 0.33), w * 0.14, Paint()..color = skinColor);
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.33),
      w * 0.14,
      _stroke(const Color(0x44000000), w * 0.02),
    );

    // Swim cap
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.78, h * 0.31),
        width: w * 0.28,
        height: h * 0.18,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFFE53935),
    );

    // Splash
    for (int i = 0; i < 5; i++) {
      final angle = (i * 40 - 100) * math.pi / 180;
      canvas.drawCircle(
        Offset(
          w * 0.24 + math.cos(angle) * w * 0.12,
          h * 0.56 + math.sin(angle) * h * 0.08,
        ),
        w * 0.025,
        Paint()..color = Colors.lightBlue.shade200,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwimmerPainter old) => old.found != found;
}

// ── Umbrella ─────────────────────────────────────────────────────────────────

class _UmbrellaPainter extends CustomPainter {
  _UmbrellaPainter({required this.found});
  final bool found;

  static const _sectors = [
    Color(0xFFE53935),
    Color(0xFFFF8F00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = h * 0.38;
    final r = w * 0.44;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r + h * 0.05),
        width: r * 1.2,
        height: r * 0.11,
      ),
      Paint()..color = const Color(0x33000000),
    );

    // Dome: 6 pie slices of upper semicircle (counterclockwise from left)
    final domeRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    for (int i = 0; i < _sectors.length; i++) {
      canvas.drawArc(
        domeRect,
        math.pi - i * (math.pi / _sectors.length),
        -math.pi / _sectors.length,
        true,
        Paint()
          ..color = found ? _sectors[i].withValues(alpha: 0.55) : _sectors[i],
      );
    }

    // Outline
    canvas.drawArc(domeRect, math.pi, -math.pi, false, _stroke(const Color(0x66000000), w * 0.025));
    canvas.drawLine(
      Offset(cx - r, cy),
      Offset(cx + r, cy),
      _stroke(const Color(0x55000000), w * 0.02),
    );

    // Depth sheen
    canvas.drawArc(
      domeRect,
      math.pi,
      -math.pi,
      true,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.15),
          ],
        ).createShader(domeRect),
    );

    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy + r + h * 0.03), handlePaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - w * 0.08, cy + r + h * 0.03),
        width: w * 0.16,
        height: h * 0.11,
      ),
      0,
      math.pi,
      false,
      handlePaint,
    );

    _highlight(canvas, Offset(cx - r * 0.35, cy - r * 0.28), r * 0.30, r * 0.17);
  }

  @override
  bool shouldRepaint(covariant _UmbrellaPainter old) => old.found != found;
}

// ── Car ──────────────────────────────────────────────────────────────────────

class _CarPainter extends CustomPainter {
  _CarPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyBright = found ? const Color(0xFF69F0AE) : const Color(0xFFE53935);
    final bodyDark = found ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.90),
        width: w * 0.80,
        height: h * 0.09,
      ),
      Paint()..color = const Color(0x33000000),
    );

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.50, w * 0.84, h * 0.32),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bodyBright, bodyDark],
        ).createShader(Rect.fromLTWH(w * 0.08, h * 0.50, w * 0.84, h * 0.32)),
    );
    canvas.drawRRect(bodyRRect, _stroke(const Color(0x55000000), w * 0.025));

    final roofRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.28),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(roofRRect, Paint()..color = bodyBright);
    canvas.drawRRect(roofRRect, _stroke(const Color(0x55000000), w * 0.025));

    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.30, w * 0.46, h * 0.20),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.85),
    );

    // Wheels
    for (final xf in [0.22, 0.72]) {
      final wc = Offset(w * xf, h * 0.81);
      canvas.drawCircle(wc, w * 0.14, Paint()..color = Colors.black87);
      canvas.drawCircle(wc, w * 0.09, Paint()..color = Colors.grey.shade400);
      canvas.drawCircle(wc, w * 0.045, Paint()..color = Colors.grey.shade700);
    }

    // Headlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.87, h * 0.60),
        width: w * 0.10,
        height: h * 0.08,
      ),
      Paint()..color = const Color(0xFFFFF9C4),
    );

    _highlight(canvas, Offset(w * 0.28, h * 0.54), w * 0.22, h * 0.06);
  }

  @override
  bool shouldRepaint(covariant _CarPainter old) => old.found != found;
}

// ── Key ──────────────────────────────────────────────────────────────────────

class _KeyPainter extends CustomPainter {
  _KeyPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bowCenter = Offset(w * 0.30, h * 0.42);
    final bowR = w * 0.24;
    final goldBright = found ? Colors.white : const Color(0xFFFFCA28);
    final goldDark = found ? const Color(0xFF76FF03) : const Color(0xFFE65100);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.62),
        width: w * 0.72,
        height: h * 0.07,
      ),
      Paint()..color = const Color(0x33000000),
    );

    final stemPaint = Paint()
      ..color = goldBright
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bowCenter.dx + bowR, h * 0.42),
      Offset(w * 0.90, h * 0.42),
      stemPaint,
    );

    // Teeth
    canvas.drawLine(Offset(w * 0.72, h * 0.42), Offset(w * 0.72, h * 0.57), stemPaint);
    canvas.drawLine(Offset(w * 0.83, h * 0.42), Offset(w * 0.83, h * 0.53), stemPaint);

    final bowRect = Rect.fromCircle(center: bowCenter, radius: bowR);
    canvas.drawCircle(bowCenter, bowR, _spherePaint(bowRect, goldBright, goldDark));
    canvas.drawCircle(bowCenter, bowR, _stroke(const Color(0x55000000), w * 0.025));

    // Hole
    canvas.drawCircle(bowCenter, bowR * 0.42, Paint()..color = Colors.black54);

    _highlight(
      canvas,
      Offset(bowCenter.dx - bowR * 0.32, bowCenter.dy - bowR * 0.35),
      bowR * 0.36,
      bowR * 0.22,
    );
  }

  @override
  bool shouldRepaint(covariant _KeyPainter old) => old.found != found;
}

// ── Fallback ─────────────────────────────────────────────────────────────────

class _FallbackPainter extends CustomPainter {
  _FallbackPainter({required this.found});
  final bool found;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.40;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: r);
    _shadow(canvas, center, r, r);
    canvas.drawCircle(
      center,
      r,
      _spherePaint(
        rect,
        found ? const Color(0xFFFFE082) : const Color(0xFFBDBDBD),
        found ? const Color(0xFFFF8F00) : const Color(0xFF616161),
      ),
    );
    _highlight(
      canvas,
      Offset(center.dx - r * 0.30, center.dy - r * 0.35),
      r * 0.40,
      r * 0.26,
    );
  }

  @override
  bool shouldRepaint(covariant _FallbackPainter old) => old.found != found;
}
