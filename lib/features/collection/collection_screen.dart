import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 図鑑（コレクション）画面。ワールドごとに、そのシーンの宝アイコンを
/// **未収集=影絵（グレーのシルエット）/ 収集=カラー** で並べる（D6）。
/// 初発見した宝には **new! バッジ**（D8）が付き、図鑑を開くと既読になる。
/// 先頭に「あつめた n/total」の収集プログレス（goal-gradient）を表示する。
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  /// 図鑑を開いた時点の「new!（未読の初発見）」スナップショット。
  /// この入場中はこれでバッジを出し、永続側は開いた時点で既読にする。
  Set<String> _unseen = const {};

  /// 図鑑のビュー: false=ワールド別（既定・D6）/ true=なかま別（D4）。
  bool _byCategory = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(activeSlotProvider) == null) {
      return; // スロット未選択（通常は router redirect で /slots へ）
    }
    final repo = ref.read(collectionRepositoryProvider);
    _unseen = repo.unseen();
    // 図鑑を開いた = いま表示する分だけを既読化する（全消しでなく snapshot 限定に
    // することで、見ている最中に増えた初発見を取りこぼさない）。失敗はログのみ。
    unawaited(
      repo.markSeen(_unseen).catchError((Object e) {
        debugPrint('collection markSeen failed: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    // スロット未選択の防御（collectionRepositoryProvider は slot null で throw）。
    final activeSlot = ref.watch(activeSlotProvider);
    if (activeSlot == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final catalogAsync = ref.watch(collectionCatalogProvider);
    // discovered() はビルド毎に prefs を読む。図鑑は /collection への新規入場で
    // 都度ビルドされ最新の収集状況を読む（発見は /hunt で起き record がキャッシュを
    // 同期更新済みなので、再入場で必ず反映される）。
    final discovered = ref.watch(collectionRepositoryProvider).discovered();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(tr(localeCode, 'collection.title')),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (worlds) {
          final progress = collectionProgressOf(worlds, discovered);
          // F3: 図鑑をコンプリートしたら最上級トレイル（rainbowFull）を解放する
          //（Hard 全クリアと並ぶもう 1 つの到達ルート）。ビルド中に副作用を出さない
          // よう post-frame で実行する。_grantCompletionReward は冪等（解放済みなら
          // no-op）なので、完成中の再ビルドで複数回スケジュールされても害はない。
          if (progress.isComplete) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _grantCompletionReward(),
            );
          }
          // C4: 見つけたレア宝（base カタログ外）。見つかった分だけ「とくべつ」に
          // 並べる（影絵は出さない＝サプライズ性を保つ・100% には影響しない）。
          // エントリは `sceneId:iconId` 形式 → 最初の ':' 以降が iconId。
          // ワールドをまたいで同じレアは 1 つに畳む（toSet）。
          final foundRares = discovered
              .map((e) => e.substring(e.indexOf(':') + 1))
              .where(isRareIcon)
              .toSet()
              .toList();
          return ListView(
            key: const ValueKey('collection-list'),
            padding: const EdgeInsets.all(16),
            children: [
              _ProgressHeader(progress: progress, localeCode: localeCode),
              const SizedBox(height: 12),
              // D4: ワールド別 / なかま別 のビュー切替。
              _ViewToggle(
                byCategory: _byCategory,
                localeCode: localeCode,
                onChanged: (v) => setState(() => _byCategory = v),
              ),
              const SizedBox(height: 12),
              if (foundRares.isNotEmpty) ...[
                _RareSection(rareIconIds: foundRares, localeCode: localeCode),
                const SizedBox(height: 12),
              ],
              if (_byCategory)
                for (final group in buildCategoryView(worlds, discovered))
                  _CategorySection(group: group, localeCode: localeCode)
              else
                for (final world in worlds)
                  _WorldSection(
                    world: world,
                    discovered: discovered,
                    unseen: _unseen,
                    localeCode: localeCode,
                  ),
            ],
          );
        },
      ),
    );
  }

  /// 図鑑コンプリート報酬（F3）: 最上級トレイルを sticky 解放する。冪等。
  void _grantCompletionReward() {
    if (!mounted) return;
    final settings = ref.read(settingsRepositoryProvider);
    if (settings.trailStyleUnlocked(TrailStyle.rainbowFull.id)) {
      return; // 既に解放済み（Hard 全クリア等）
    }
    // 永続化が完了してから解放集合を再評価する（invalidate と書き込みの競合回避）。
    unawaited(
      settings
          .setTrailStyleUnlocked(TrailStyle.rainbowFull.id)
          .then((_) {
            if (mounted) ref.invalidate(unlockedTrailStylesProvider);
          })
          .catchError((Object e) {
            debugPrint('collection reward unlock failed: $e');
          }),
    );
  }
}

/// 全体の収集プログレス。完成で祝福（goal-gradient を内発的に）。
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress, required this.localeCode});

  final CollectionProgress progress;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final complete = progress.isComplete;
    return Card(
      key: const ValueKey('collection-progress'),
      color: complete ? Colors.amber.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              complete ? Icons.emoji_events : Icons.menu_book,
              color: complete ? Colors.amber.shade800 : Colors.brown.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                complete
                    ? tr(localeCode, 'collection.allDone')
                    : '${tr(localeCode, 'collection.collected')} '
                          '${progress.found}/${progress.total}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 図鑑のビュー切替（ワールド別 / なかま別・D4）。
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.byCategory,
    required this.localeCode,
    required this.onChanged,
  });

  final bool byCategory;
  final String localeCode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<bool>(
        key: const ValueKey('collection-view-toggle'),
        segments: [
          ButtonSegment(
            value: false,
            label: Text(tr(localeCode, 'collection.byWorld')),
            icon: const Icon(Icons.public),
          ),
          ButtonSegment(
            value: true,
            label: Text(tr(localeCode, 'collection.byCategory')),
            icon: const Icon(Icons.category),
          ),
        ],
        selected: {byCategory},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// なかま（カテゴリ）別の 1 グループ。カテゴリ絵＋ラベル＋宝セル（影絵→カラー）。
class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.group, required this.localeCode});

  final CategoryGroup group;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('collection-category.${group.category.name}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(group.category.icon, color: Colors.brown.shade700),
                const SizedBox(width: 8),
                Text(
                  tr(localeCode, group.category.labelKey),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in group.icons)
                  _CollectionCell(
                    sceneId: 'cat.${group.category.name}',
                    iconId: e.iconId,
                    discovered: e.found,
                    isNew: false,
                    localeCode: localeCode,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 見つけたレア宝（C4）を並べる「とくべつ」カード。見つけた分だけカラーで表示し、
/// 影絵（未収集）は出さない（サプライズ性を保つ・100% 判定にも影響しない）。
class _RareSection extends StatelessWidget {
  const _RareSection({required this.rareIconIds, required this.localeCode});

  final List<String> rareIconIds;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('collection-rare'),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  tr(localeCode, 'collection.rare'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final iconId in rareIconIds)
                  Container(
                    key: ValueKey('collection-rare.$iconId'),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.amber.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(
                            targetIcon(iconId),
                            color: targetColor(iconId),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 ワールド分のカード。見出し（ワールド名 ＋ n/total）＋ 宝セルの折り返し。
class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.world,
    required this.discovered,
    required this.unseen,
    required this.localeCode,
  });

  final CollectionWorld world;
  final Set<String> discovered;
  final Set<String> unseen;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final foundCount = world.iconIds
        .where(
          (ic) => discovered.contains(
            CollectionRepository.entryKey(world.sceneId, ic),
          ),
        )
        .length;
    final total = world.iconIds.length;
    final complete = total > 0 && foundCount >= total;

    return Card(
      key: ValueKey('collection-world.${world.sceneId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(localeCode, world.titleKey),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$foundCount/$total ${complete ? '🏆' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final iconId in world.iconIds)
                  _CollectionCell(
                    sceneId: world.sceneId,
                    iconId: iconId,
                    discovered: discovered.contains(
                      CollectionRepository.entryKey(world.sceneId, iconId),
                    ),
                    isNew: unseen.contains(
                      CollectionRepository.entryKey(world.sceneId, iconId),
                    ),
                    localeCode: localeCode,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 宝 1 つのセル。収集済みはカラー、未収集は影絵。初発見は new! バッジ付き。
class _CollectionCell extends StatelessWidget {
  const _CollectionCell({
    required this.sceneId,
    required this.iconId,
    required this.discovered,
    required this.isNew,
    required this.localeCode,
  });

  final String sceneId;
  final String iconId;
  final bool discovered;
  final bool isNew;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: ValueKey('collection-cell.$sceneId.$iconId'),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: discovered ? Colors.amber.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.brown.shade300, width: 2),
          ),
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: FittedBox(
                fit: BoxFit.contain,
                child: discovered
                    ? Icon(
                        targetIcon(iconId),
                        color: targetColor(iconId),
                        key: ValueKey('collection-found.$sceneId.$iconId'),
                      )
                    : UnfoundTreasureIcon(
                        key: ValueKey('collection-silhouette.$sceneId.$iconId'),
                        iconId: iconId,
                      ),
              ),
            ),
          ),
        ),
        if (discovered && isNew)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              key: ValueKey('collection-new.$sceneId.$iconId'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr(localeCode, 'collection.new'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
