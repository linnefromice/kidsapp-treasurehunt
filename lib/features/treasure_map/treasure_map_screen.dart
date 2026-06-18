import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

class TreasureMapScreen extends ConsumerWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final clearedCount = kSceneCatalog
        .where((e) => progress.isCleared(e.id))
        .length;

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
                '$clearedCount/${kSceneCatalog.length} 🏆',
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
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                ),
              ),
              CustomPaint(
                size: size,
                painter: _TrailPainter(
                  progress: progress,
                  clearedIds: kSceneCatalog
                      .where((e) => progress.isCleared(e.id))
                      .map((e) => e.id)
                      .toSet(),
                ),
              ),
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

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.progress, required this.clearedIds});

  final ProgressRepository progress;
  final Set<String> clearedIds;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < kSceneCatalog.length - 1; i++) {
      final a = kSceneCatalog[i];
      final b = kSceneCatalog[i + 1];
      final p0 = Offset(a.mapPos.dx * size.width, a.mapPos.dy * size.height);
      final p1 = Offset(b.mapPos.dx * size.width, b.mapPos.dy * size.height);
      final done = progress.isCleared(a.id);
      final paint = Paint()
        ..color = done ? Colors.brown.shade600 : Colors.brown.shade200
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawBezierDashed(canvas, p0, p1, paint);
    }
  }

  void _drawBezierDashed(Canvas canvas, Offset p0, Offset p1, Paint paint) {
    final midY = (p0.dy + p1.dy) / 2;
    final cp1 = Offset(p0.dx, midY);
    final cp2 = Offset(p1.dx, midY);

    final fullPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);

    final pathMetrics = fullPath.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;
    final metric = pathMetrics.first;

    const dashLen = 12.0;
    const gapLen = 8.0;
    var dist = 0.0;
    while (dist < metric.length) {
      final end = (dist + dashLen).clamp(0.0, metric.length);
      final dashPath = metric.extractPath(dist, end);
      canvas.drawPath(dashPath, paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      !setEquals(oldDelegate.clearedIds, clearedIds);
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
        : Colors.grey.shade400;

    Widget medallion = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(
        widget.entry.themeIcon,
        key: ValueKey(stateKey),
        color: color,
        size: 40,
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
