import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/treasure_map_canvas.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 「現在地」= まだクリアしていない最初の解放済みシーンの index。
/// 全クリア / 先頭未解放なら null（マーチング足跡を出さない）。
int? _currentNodeIndex(ProgressRepository progress) {
  for (var i = 0; i < kSceneCatalog.length; i++) {
    final e = kSceneCatalog[i];
    if (progress.isUnlocked(e.id) && !progress.isCleared(e.id)) return i;
  }
  return null;
}

class TreasureMapScreen extends ConsumerWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final clearedIds = kSceneCatalog
        .where((e) => progress.isCleared(e.id))
        .map((e) => e.id)
        .toSet();
    final currentIndex = _currentNodeIndex(progress);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            ref.read(activeSlotProvider.notifier).deselect();
            context.go('/slots');
          },
        ),
        title: Text(tr(localeCode, 'home.title')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${tr(localeCode, 'home.cleared')} '
                '${clearedIds.length}/${kSceneCatalog.length} 🏆',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 羊皮紙背景（静的・隔離）
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: const ParchmentPainter(),
                ),
              ),
              // 2. 曲線ルート + クリア済み区間の足跡（クリア時のみ再描画・隔離）
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: TrailPainter(clearedIds: clearedIds),
                ),
              ),
              // 3. 現在地へ向かう足跡（アニメ・隔離）。現在地が無ければ描かない。
              if (currentIndex != null && currentIndex > 0)
                RepaintBoundary(
                  child: _CurrentLegFootprints(
                    size: size,
                    endIndex: currentIndex,
                  ),
                ),
              // 4. ノード群
              for (final entry in kSceneCatalog)
                Positioned(
                  left: entry.mapPos.dx * size.width - 56,
                  top: entry.mapPos.dy * size.height - 56,
                  width: 112,
                  height: 112,
                  child: _MapNode(
                    entry: entry,
                    localeCode: localeCode,
                    unlocked: progress.isUnlocked(entry.id),
                    cleared: progress.isCleared(entry.id),
                    onTap: progress.isUnlocked(entry.id)
                        ? () => context.go('/hunt/${entry.id}')
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 現在地へ向かう 1 区間だけに、足跡が順番にフェードインする「マーチング」演出。
/// 低振幅・緩ループで、進む方向をそっと誘目する（急かさない）。
class _CurrentLegFootprints extends StatefulWidget {
  const _CurrentLegFootprints({required this.size, required this.endIndex});

  final Size size;
  final int endIndex;

  @override
  State<_CurrentLegFootprints> createState() => _CurrentLegFootprintsState();
}

class _CurrentLegFootprintsState extends State<_CurrentLegFootprints>
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

class _MapNode extends StatefulWidget {
  const _MapNode({
    required this.entry,
    required this.localeCode,
    required this.unlocked,
    required this.cleared,
    required this.onTap,
  });

  final SceneCatalogEntry entry;
  final String localeCode;
  final bool unlocked;
  final bool cleared;
  final VoidCallback? onTap;

  @override
  State<_MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<_MapNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _isCurrent => widget.unlocked && !widget.cleared;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (_isCurrent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MapNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_isCurrent && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateKey = widget.cleared
        ? 'node-cleared.${widget.entry.id}'
        : widget.unlocked
        ? 'node-current.${widget.entry.id}'
        : 'node-locked.${widget.entry.id}';
    final color = widget.cleared
        ? Colors.amber.shade600
        : widget.unlocked
        ? Colors.orange.shade400
        : Colors.brown.shade300;

    // ロックは「未踏の地」らしくセピア寄せ（白地 → 褪せた羊皮紙色）にして
    // 自然に視線を外させる。Opacity レイヤを使わず色だけで表現（saveLayer 回避）。
    final fill = widget.unlocked ? Colors.white : const Color(0xFFEDE3D2);

    Widget medallion = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: widget.unlocked ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.entry.themeIcon,
        key: ValueKey(stateKey),
        color: color,
        size: 34,
      ),
    );

    if (_isCurrent) {
      medallion = ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 1.12,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: medallion,
      );
    }

    return GestureDetector(
      key: ValueKey('scene-node.${widget.entry.id}'),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCurrent) _GlowRing(pulse: _pulse),
                medallion,
                if (!widget.unlocked)
                  const Icon(Icons.lock, color: Colors.brown, size: 26),
                if (widget.cleared)
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(widget.localeCode, widget.entry.titleKey),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 現在ノードの背後で呼吸する発光リング。`_pulse` に同期して半径と濃さが揺れる。
class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 12 + 10 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
