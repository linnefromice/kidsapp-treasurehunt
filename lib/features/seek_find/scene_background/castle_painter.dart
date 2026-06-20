part of '../scene_background.dart';

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

    // Three towers with battlements; index 1 is the central tower.
    const towerXs = [0.28, 0.50, 0.72];
    const centerTowerIndex = 1;
    final towerW = size.width * 0.10;
    for (int t = 0; t < towerXs.length; t++) {
      final cx = towerXs[t];
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
      if (t != centerTowerIndex) {
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
        ..strokeWidth = size.width * 0.006,
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
