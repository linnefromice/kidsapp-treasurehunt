import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/treasure_map_canvas.dart';

/// 現在地へ向かう 1 区間だけに、足跡が順番にフェードインする「マーチング」演出。
/// 低振幅・緩ループで、進む方向をそっと誘目する（急かさない）。
class CurrentLegFootprints extends StatefulWidget {
  const CurrentLegFootprints({
    super.key,
    required this.size,
    required this.endIndex,
  });

  final Size size;
  final int endIndex;

  @override
  State<CurrentLegFootprints> createState() => _CurrentLegFootprintsState();
}

class _CurrentLegFootprintsState extends State<CurrentLegFootprints>
    with SingleTickerProviderStateMixin {
  late final AnimationController _march;

  @override
  void initState() {
    super.initState();
    _march = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _march.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _march,
      builder: (context, _) => CustomPaint(
        size: widget.size,
        painter: _LegFootstepsPainter(
          t: _march.value,
          endIndex: widget.endIndex,
        ),
      ),
    );
  }
}

/// `endIndex` 区間に等間隔の足跡を置き、`t`（0..1 ループ）に応じて先頭から順に
/// 明滅させる。先頭位置は環状に巻き戻るので連続的な行進に見える。
class _LegFootstepsPainter extends CustomPainter {
  _LegFootstepsPainter({required this.t, required this.endIndex});

  final double t;
  final int endIndex;

  static const int _count = 8;
  static const Color _color = Color(0xFFFF8F00);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = trailNodeCenters(size);
    final path = legPath(pts, endIndex);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final head = t * _count;
    var side = 1.0;
    for (var i = 0; i < _count; i++) {
      final dist = ((i + 0.5) / _count) * metric.length;
      final tan = metric.getTangentForOffset(dist);
      if (tan == null) {
        side = -side;
        continue;
      }
      // 行進する「光の頭」が i を通過する時に最も明るく。環状の最短距離で評価。
      final raw = head - i;
      final wrapped = math.min(
        raw.abs(),
        math.min((raw - _count).abs(), (raw + _count).abs()),
      );
      final wave = math.exp(-(wrapped * wrapped) / 1.2);
      final alpha = (0.18 + 0.55 * wave).clamp(0.0, 0.85);

      final normal = Offset(-tan.vector.dy, tan.vector.dx);
      paintFootprint(
        canvas,
        tan.position + normal * (5.0 * side),
        tan.angle,
        _color.withValues(alpha: alpha),
      );
      side = -side;
    }
  }

  // `t` は毎フレーム変化する連続値のため、常に再描画が必要。
  @override
  bool shouldRepaint(_LegFootstepsPainter oldDelegate) => true;
}
