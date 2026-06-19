import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

class SeekFindScreen extends ConsumerWidget {
  const SeekFindScreen({super.key, required this.sceneId});

  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneAsync = ref.watch(sceneProvider(sceneId));
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
      body: sceneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (scene) => _SceneView(scene: scene),
      ),
    );
  }
}

class _SceneView extends ConsumerStatefulWidget {
  const _SceneView({required this.scene});

  final SceneDef scene;

  @override
  ConsumerState<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends ConsumerState<_SceneView> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(scene.id));

    ref.listen(foundControllerProvider(scene.id), (previous, next) {
      final wasComplete = (previous?.length ?? 0) >= scene.targets.length;
      final nowComplete = next.length >= scene.targets.length;
      if (!wasComplete && nowComplete) {
        _handleComplete(scene.id);
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sceneSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _handleHit(d.localPosition, sceneSize),
                    onPanStart: (d) => _handleHit(d.localPosition, sceneSize),
                    onPanUpdate: (d) => _handleHit(d.localPosition, sceneSize),
                    child: Stack(
                      key: const ValueKey('scene-content'),
                      fit: StackFit.expand,
                      children: [
                        sceneBackground(scene.id),
                        for (final d in scene.dummies)
                          Positioned(
                            left: d.normalizedRect.left * sceneSize.width,
                            top: d.normalizedRect.top * sceneSize.height,
                            width: d.normalizedRect.width * sceneSize.width,
                            height: d.normalizedRect.height * sceneSize.height,
                            child: _TargetView(iconId: d.iconId, found: false),
                          ),
                        for (final t in scene.targets)
                          Positioned(
                            left: t.normalizedRect.left * sceneSize.width,
                            top: t.normalizedRect.top * sceneSize.height,
                            width: t.normalizedRect.width * sceneSize.width,
                            height: t.normalizedRect.height * sceneSize.height,
                            child: _TargetView(
                              iconId: t.iconId,
                              found: found.contains(t.id),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            CollectionBar(
              targets: scene.targets,
              foundIds: found,
            ),
          ],
        ),
        if (_completed)
          _ClearOverlay(localeCode: localeCode, onBack: () => context.go('/')),
      ],
    );
  }

  Future<void> _handleComplete(String sceneId) async {
    await completeScene(ref.read(progressRepositoryProvider), sceneId);
    await ref.read(audioServiceProvider).playComplete();
    if (mounted) setState(() => _completed = true);
  }

  void _handleHit(Offset localPosition, Size sceneSize) {
    final scene = widget.scene;
    final found = ref.read(foundControllerProvider(scene.id));
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: sceneSize,
      targets: scene.targets,
      foundIds: found,
    );
    if (hitId == null) return;
    ref.read(foundControllerProvider(scene.id).notifier).markFound(hitId);
    HapticFeedback.lightImpact();
    ref.read(audioServiceProvider).playFound();
  }
}

class _TargetView extends StatelessWidget {
  const _TargetView({required this.iconId, required this.found});

  final String iconId;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      // Clip.none lets FoundBurst sparks radiate beyond the target bounds
      clipBehavior: Clip.none,
      children: [
        if (found) RepaintBoundary(child: _FoundGlow(color: targetColor(iconId))),
        FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            targetIcon(iconId),
            color: found
                ? targetColor(iconId)
                : Colors.grey.shade400.withValues(alpha: 0.45),
          ),
        ),
        if (found) FoundBurst(color: targetColor(iconId)),
      ],
    );
  }
}

class _FoundGlow extends StatefulWidget {
  const _FoundGlow({required this.color});

  final Color color;

  @override
  State<_FoundGlow> createState() => _FoundGlowState();
}

class _FoundGlowState extends State<_FoundGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0.0 → 1.0 → 0.0 (reverse)
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45 * t),
                blurRadius: 16 + 8 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────
// Clear overlay: full-screen キラキラ + message + back button
// ──────────────────────────────────────────

class _ClearOverlay extends StatefulWidget {
  const _ClearOverlay({required this.localeCode, required this.onBack});

  final String localeCode;
  final VoidCallback onBack;

  @override
  State<_ClearOverlay> createState() => _ClearOverlayState();
}

class _ClearOverlayState extends State<_ClearOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Normalized [x, y, phaseOffset] for twinkling stars. Explicit List<List<double>>
  // type prevents Dart inferring List<List<num>> from the literal.
  static const List<List<double>> _kStars = [
    [0.06, 0.08, 0.0],
    [0.22, 0.05, 0.3],
    [0.42, 0.12, 0.6],
    [0.62, 0.06, 0.1],
    [0.80, 0.10, 0.5],
    [0.93, 0.04, 0.8],
    [0.14, 0.24, 0.2],
    [0.36, 0.20, 0.7],
    [0.58, 0.27, 0.4],
    [0.78, 0.22, 0.9],
    [0.04, 0.44, 0.6],
    [0.28, 0.40, 0.1],
    [0.52, 0.38, 0.3],
    [0.74, 0.45, 0.8],
    [0.94, 0.42, 0.2],
    [0.10, 0.62, 0.5],
    [0.35, 0.68, 0.0],
    [0.66, 0.60, 0.7],
    [0.86, 0.65, 0.4],
    [0.20, 0.80, 0.9],
    [0.50, 0.84, 0.2],
    [0.72, 0.78, 0.6],
    [0.90, 0.88, 0.1],
  ];

  @override
  void dispose() {
    _entry.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _entry,
        child: Stack(
          children: [
            // Dark translucent backdrop — SizedBox.expand prevents the
            // DecoratedBox from collapsing to zero under loose Stack constraints.
            const SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000830), Color(0xCC001040)],
                  ),
                ),
              ),
            ),
            // Twinkling stars
            AnimatedBuilder(
              animation: _sparkle,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparklePainter(_sparkle.value, _kStars),
                  size: Size.infinite,
                );
              },
            ),
            // Center message + button
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _entry,
                  curve: Curves.elasticOut,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingStarIcon(controller: _sparkle),
                    const SizedBox(height: 20),
                    Text(
                      tr(widget.localeCode, 'seek.complete'),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 16,
                            color: Colors.amber,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    KidsButton(
                      label: tr(widget.localeCode, 'seek.toMap'),
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.t, this.stars);

  final double t;
  final List<List<double>> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final phase = (t + s[2]) % 1.0;
      final brightness = math.sin(phase * math.pi);
      final opacity = (brightness * 0.85).clamp(0.0, 1.0);
      final r = 3.0 + brightness * 7.0;
      final cx = s[0] * size.width;
      final cy = s[1] * size.height;
      // Outer glow
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.8,
        Paint()..color = Colors.amber.withValues(alpha: opacity * 0.35),
      );
      // Core dot
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = Colors.amber.withValues(alpha: opacity),
      );
      // White center
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.38,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

class _PulsingStarIcon extends AnimatedWidget {
  const _PulsingStarIcon({required this.controller})
    : super(listenable: controller);

  // Typed field avoids unsafe `as AnimationController` cast in build.
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + math.sin(controller.value * 2 * math.pi) * 0.15;
    return Transform.scale(
      scale: scale,
      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 80),
    );
  }
}
