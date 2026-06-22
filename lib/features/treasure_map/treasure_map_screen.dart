import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/current_leg_footprints.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/map_mode_toggle.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/map_node.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/trail_badge.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/treasure_map_canvas.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 選択中モードでの「現在地」= まだクリアしていない最初の解放済みシーンの index。
/// 全クリア / 先頭未解放なら null（マーチング足跡を出さない）。
int? _currentNodeIndex(ProgressRepository progress, GameMode mode) {
  for (var i = 0; i < kSceneCatalog.length; i++) {
    final e = kSceneCatalog[i];
    if (progress.isUnlocked(mode, e.id) && !progress.isCleared(mode, e.id)) {
      return i;
    }
  }
  return null;
}

class TreasureMapScreen extends ConsumerStatefulWidget {
  const TreasureMapScreen({super.key});

  @override
  ConsumerState<TreasureMapScreen> createState() => _TreasureMapScreenState();
}

class _TreasureMapScreenState extends ConsumerState<TreasureMapScreen> {
  @override
  void initState() {
    super.initState();
    // 既存スロット救済: 各モードの初期解放（scene01）が無ければ遅延シードする。
    // スロット生成時に 3 モード分シード済みのため、通常は冪等で no-op。
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSeeded());
  }

  Future<void> _ensureSeeded() async {
    // アクティブスロット未選択なら progressRepositoryProvider は throw する。
    // この postFrameCallback は unawaited のため、ここで握って no-op にする
    // （ルート遷移の境界でスロットが外れた瞬間などを防御）。
    if (!mounted || ref.read(activeSlotProvider) == null) return;
    final progress = ref.read(progressRepositoryProvider);
    var seeded = false;
    for (final mode in GameMode.values) {
      if (progress.unlockedSceneIds(mode).isEmpty) {
        await progress.ensureInitialUnlock(mode, kFirstSceneId);
        seeded = true;
      }
    }
    if (seeded && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final trail = ref.watch(trailSettingControllerProvider);
    final activeSlotId = ref.watch(activeSlotProvider);
    // 難易度は永続化された設定から取得する。クリア後にホームへ戻って画面が
    // 作り直されても選択が維持される（Bug A: easy へのリセットを防ぐ）。
    final mode = ref.watch(gameModeControllerProvider);
    final avatarEmoji = ref.watch(
      saveSlotControllerProvider.select(
        (slots) => (activeSlotId != null && activeSlotId != kFreeModeSlotId)
            ? slots[activeSlotId]
            : null,
      ),
    );

    final isHard = mode == GameMode.hard;
    // バッジ・カウンタ・軌跡・現在地はすべて選択中モードの進捗を反映する。
    final clearedForMode = kSceneCatalog
        .where((e) => progress.isCleared(mode, e.id))
        .map((e) => e.id)
        .toSet();
    final currentIndex = _currentNodeIndex(progress, mode);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('avatar-button'),
          icon: avatarEmoji != null
              ? Text(avatarEmoji, style: const TextStyle(fontSize: 28))
              : const Icon(Icons.person),
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
                '${clearedForMode.length}/${kSceneCatalog.length} '
                '${isHard ? '🏆🔥' : '🏆'}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          TrailBadge(setting: trail, onTap: () => context.go('/settings')),
          IconButton(
            key: const ValueKey('collection-button'),
            icon: const Icon(Icons.menu_book),
            tooltip: tr(localeCode, 'home.collection'),
            onPressed: () => context.go('/collection'),
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
              // 2. 曲線ルート + クリア済み区間の足跡（選択中モードのクリアを反映）
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: TrailPainter(clearedIds: clearedForMode),
                ),
              ),
              // 3. 現在地へ向かう足跡（アニメ・隔離）。現在地が無ければ描かない。
              if (currentIndex != null && currentIndex > 0)
                RepaintBoundary(
                  child: CurrentLegFootprints(
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
                  child: MapNode(
                    entry: entry,
                    localeCode: localeCode,
                    unlocked: progress.isUnlocked(mode, entry.id),
                    cleared: clearedForMode.contains(entry.id),
                    onTap: progress.isUnlocked(mode, entry.id)
                        ? () =>
                              context.go('/hunt/${entry.id}?mode=${mode.name}')
                        : null,
                  ),
                ),
              // 5. モード切替トグル（Easy / Normal / Hard を常時表示）
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: MapModeToggle(
                    mode: mode,
                    localeCode: localeCode,
                    onChanged: (m) =>
                        ref.read(gameModeControllerProvider.notifier).select(m),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
