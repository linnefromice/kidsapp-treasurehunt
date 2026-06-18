import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

const Map<String, List<Color>> _sceneGradients = {
  'scene01': [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
  'scene02': [Color(0xFFBBDEFB), Color(0xFFB3E5FC)],
  'scene03': [Color(0xFFE1F5FE), Color(0xFFD1C4E9)],
};

List<Color> _gradientFor(String sceneId) =>
    _sceneGradients[sceneId] ?? const [Color(0xFFB2DFDB), Color(0xFFC8E6C9)];

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

    return Column(
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
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _gradientFor(scene.id),
                        ),
                      ),
                    ),
                    for (final t in scene.targets)
                      Positioned(
                        left: t.normalizedRect.left * sceneSize.width,
                        top: t.normalizedRect.top * sceneSize.height,
                        width: t.normalizedRect.width * sceneSize.width,
                        height: t.normalizedRect.height * sceneSize.height,
                        child: _TargetView(
                          icon: targetIcon(t.id),
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
          targetIds: [for (final t in scene.targets) t.id],
          foundIds: found,
        ),
        if (_completed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(localeCode, 'seek.complete'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                KidsButton(
                  label: tr(localeCode, 'seek.toMap'),
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
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
    ref.read(audioServiceProvider).playFound();
  }
}

class _TargetView extends StatelessWidget {
  const _TargetView({required this.icon, required this.found});

  final IconData icon;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            icon,
            color: found ? Colors.amber.shade700 : Colors.brown.shade600,
          ),
        ),
        if (found) const FoundBurst(),
      ],
    );
  }
}
