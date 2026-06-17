import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';

const Size kSceneSize = Size(800, 600);

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

    // 完了は副作用なので build 中では実行せず、ref.listen で
    // 「全発見になった瞬間」に一度だけ発火させる。
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
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              onTapDown: (details) =>
                  _handleTap(details.localPosition, scene, found),
              child: SizedBox(
                key: const ValueKey('scene-content'),
                width: kSceneSize.width,
                height: kSceneSize.height,
                child: Stack(
                  children: [
                    // プレースホルダ背景(実アートは後で差し替え)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
                        ),
                      ),
                    ),
                    // 見つけた宝の位置に印 + バースト
                    for (final t in scene.targets)
                      if (found.contains(t.id))
                        Positioned(
                          left: t.normalizedRect.left * kSceneSize.width,
                          top: t.normalizedRect.top * kSceneSize.height,
                          width: t.normalizedRect.width * kSceneSize.width,
                          height: t.normalizedRect.height * kSceneSize.height,
                          child: const FoundBurst(),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        CollectionBar(
          targetIds: [for (final t in scene.targets) t.id],
          foundIds: found,
        ),
        if (_completed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr(localeCode, 'seek.complete'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Future<void> _handleComplete(String sceneId) async {
    await ref.read(progressRepositoryProvider).markCleared(sceneId);
    await ref.read(audioServiceProvider).playComplete();
    if (mounted) setState(() => _completed = true);
  }

  void _handleTap(Offset localPosition, SceneDef scene, Set<String> found) {
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: kSceneSize,
      targets: scene.targets,
      foundIds: found,
    );
    if (hitId == null) return; // 空振りは罰しない
    ref.read(foundControllerProvider(scene.id).notifier).markFound(hitId);
    ref.read(audioServiceProvider).playFound();
  }
}
