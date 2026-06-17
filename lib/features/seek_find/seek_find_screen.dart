import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/strings/strings.dart';
import 'models/scene_def.dart';
import 'seek_find_logic.dart';
import 'widgets/collection_bar.dart';
import 'widgets/found_burst.dart';

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
  bool _completeHandled = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(scene.id));

    // 全発見 → 一度だけ完了処理
    if (found.length == scene.targets.length && !_completeHandled) {
      _completeHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(progressRepositoryProvider).markCleared(scene.id);
        await ref.read(audioServiceProvider).playComplete();
        if (mounted) setState(() {});
      });
    }

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
        if (_completeHandled)
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
