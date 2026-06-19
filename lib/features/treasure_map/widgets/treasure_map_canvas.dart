import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

/// 宝の地図の「羊皮紙背景」「曲線ルート」「足跡」を描く CustomPainter 群と、
/// それらが共有する曲線ジオメトリ helper。すべて SDK 標準 API のみ（追加 package なし）。

/// `kSceneCatalog` の正規化座標 `mapPos` を、与えられた描画サイズ上の画素中心に変換する。
List<Offset> trailNodeCenters(Size size) => [
  for (final e in kSceneCatalog)
    Offset(e.mapPos.dx * size.width, e.mapPos.dy * size.height),
];

/// 全ノードを通る 1 本の緩い曲線パス（古地図のうねった一本道）。
Path buildTrailPath(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  for (var i = 0; i < pts.length - 1; i++) {
    _addCurvedSegment(path, pts[i], pts[i + 1], i);
  }
  return path;
}

/// `endIndex-1 → endIndex` の 1 区間だけの曲線パス（現在地へ向かう足跡用）。
/// `buildTrailPath` と同じ index を渡すため、うねり方向が全体パスと一致する。
Path legPath(List<Offset> pts, int endIndex) {
  final path = Path();
  if (endIndex <= 0 || endIndex >= pts.length) return path;
  final a = pts[endIndex - 1];
  path.moveTo(a.dx, a.dy);
  _addCurvedSegment(path, a, pts[endIndex], endIndex - 1);
  return path;
}

/// a→b を緩い Bézier 曲線で結ぶ。制御点はセグメントに垂直な向きへ、index の
/// 偶奇で符号反転したオフセットを掛けて「決定論的なうねり」を作る（乱数なし）。
void _addCurvedSegment(Path path, Offset a, Offset b, int index) {
  final dir = b - a;
  final len = dir.distance;
  if (len == 0) {
    path.lineTo(b.dx, b.dy);
    return;
  }
  final perp = Offset(-dir.dy / len, dir.dx / len);
  final bow = perp * (len * 0.18 * (index.isEven ? 1.0 : -1.0));
  final c1 = a + dir * 0.33 + bow;
  final c2 = a + dir * 0.66 + bow;
  path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
}

/// ルート上に置く小判型の足跡を 1 個描く（静的・アニメ双方から共用）。
void paintFootprint(Canvas canvas, Offset pos, double angle, Color color) {
  canvas
    ..save()
    ..translate(pos.dx, pos.dy)
    ..rotate(angle)
    ..drawOval(
      Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
      Paint()..color = color,
    )
    ..restore();
}

/// 羊皮紙風の背景。ベース暖色グラデ + 決定論的な繊維ムラ + 焦げ枠 + コンパスローズ。
/// 完全に静的なので `shouldRepaint => false`（呼び出し側で RepaintBoundary 隔離）。
class ParchmentPainter extends CustomPainter {
  const ParchmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBEFD6), Color(0xFFEBD3A6)],
        ).createShader(rect),
    );

    // 繊維ムラ: シード固定 Random なので再描画しても同一の見た目になる。
    final rnd = math.Random(7);
    final fiber = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 120; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final segLen = 6 + rnd.nextDouble() * 18;
      final ang = rnd.nextDouble() * math.pi;
      final base = rnd.nextBool()
          ? const Color(0xFF8D6E63)
          : const Color(0xFFFFF8E1);
      fiber
        ..color = base.withValues(alpha: 0.05 + rnd.nextDouble() * 0.05)
        ..strokeWidth = 1 + rnd.nextDouble() * 1.5;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(ang) * segLen, y + math.sin(ang) * segLen),
        fiber,
      );
    }

    // 焦げ枠（ヴィネット）: 端へ向かって暗く落とす。
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x33000000), Color(0x66795548)],
          stops: [0.6, 0.85, 1.0],
        ).createShader(rect),
    );

    _drawCompassRose(canvas, size);
  }

  void _drawCompassRose(Canvas canvas, Size size) {
    final c = Offset(size.width - 56, 64);
    const r = 30.0;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0x99795548);
    canvas
      ..drawCircle(c, r, ring)
      ..drawCircle(c, r * 0.5, ring);

    final star = Paint()..color = const Color(0xAA8D6E63);
    for (var i = 0; i < 4; i++) {
      final ang = i * math.pi / 2 - math.pi / 2; // N(上)から時計回り
      final tip = c + Offset(math.cos(ang), math.sin(ang)) * r;
      final b1 =
          c +
          Offset(math.cos(ang + math.pi / 2), math.sin(ang + math.pi / 2)) *
              (r * 0.18);
      final b2 =
          c +
          Offset(math.cos(ang - math.pi / 2), math.sin(ang - math.pi / 2)) *
              (r * 0.18);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(b1.dx, b1.dy)
          ..lineTo(b2.dx, b2.dy)
          ..close(),
        star,
      );
    }

    final label = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xCC5D4037),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, c + Offset(-label.width / 2, -r - 14));
  }

  @override
  bool shouldRepaint(ParchmentPainter oldDelegate) => false;
}

/// 曲線ルート（破線）+ クリア済み区間の足跡を描く。クリア状況が変わった時だけ再描画。
class TrailPainter extends CustomPainter {
  TrailPainter({required this.clearedIds});

  final Set<String> clearedIds;

  static const double _dashLen = 12.0;
  static const double _gapLen = 8.0;
  static const double _footStep = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = trailNodeCenters(size);
    if (pts.length < 2) return;

    for (var i = 0; i < pts.length - 1; i++) {
      final done = clearedIds.contains(kSceneCatalog[i].id);
      final seg = Path()..moveTo(pts[i].dx, pts[i].dy);
      _addCurvedSegment(seg, pts[i], pts[i + 1], i);

      final paint = Paint()
        ..color = done ? const Color(0xFF6D4C41) : const Color(0xFFD7CCC8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawDashed(canvas, seg, paint);

      if (done) _drawFootprints(canvas, seg);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final end = (dist + _dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += _dashLen + _gapLen;
      }
    }
  }

  void _drawFootprints(Canvas canvas, Path path) {
    const color = Color(0x668D6E63);
    for (final metric in path.computeMetrics()) {
      var dist = 20.0;
      var side = 1.0;
      while (dist < metric.length) {
        final tan = metric.getTangentForOffset(dist);
        if (tan != null) {
          final normal = Offset(-tan.vector.dy, tan.vector.dx);
          paintFootprint(
            canvas,
            tan.position + normal * (5.0 * side),
            tan.angle,
            color,
          );
        }
        dist += _footStep;
        side = -side;
      }
    }
  }

  @override
  bool shouldRepaint(TrailPainter oldDelegate) =>
      !setEquals(oldDelegate.clearedIds, clearedIds);
}
