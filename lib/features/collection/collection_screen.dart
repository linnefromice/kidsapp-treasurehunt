import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/badges/badge_service.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/widgets/badge_gallery.dart';
import 'package:kidsapp_treasurehunt/features/collection/widgets/collection_sections.dart';
import 'package:kidsapp_treasurehunt/features/collection/widgets/sticker_book.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
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

  /// 図鑑のビュー: ワールド別（既定・D6）/ なかま別（D4）/ しょうごう（B-3）。
  CollectionView _view = CollectionView.world;

  /// 「しょうごう」入場時の未読バッチスナップショット（この入場中だけ NEW を出す）。
  Set<String> _badgeUnseenSnapshot = const {};

  /// シール帳の現在ページ。なかま⇄ワールドのビュー往復で StickerBook が
  /// 作り直されてもページ位置を保つために親が覚えておく（D1）。
  int _bookPage = 0;

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
          return Column(
            key: const ValueKey('collection-list'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    ProgressHeader(progress: progress, localeCode: localeCode),
                    const SizedBox(height: 12),
                    // ワールド別 / なかま別 / しょうごう のビュー切替。
                    ViewToggle(
                      view: _view,
                      localeCode: localeCode,
                      hasNewBadge: ref
                          .watch(badgeRepositoryProvider)
                          .unseen()
                          .isNotEmpty,
                      onChanged: _onViewChanged,
                    ),
                    if (foundRares.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      RareSection(
                        rareIconIds: foundRares,
                        localeCode: localeCode,
                      ),
                    ],
                  ],
                ),
              ),
              // ワールド別=シール帳（D1）/ なかま別=リスト / しょうごう=バッチ。
              Expanded(
                child: switch (_view) {
                  CollectionView.category => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final group in buildCategoryView(worlds, discovered))
                        CategorySection(group: group, localeCode: localeCode),
                    ],
                  ),
                  CollectionView.badge => BadgeGallery(
                    earned: ref.watch(badgeRepositoryProvider).earned(),
                    unseen: _badgeUnseenSnapshot,
                    localeCode: localeCode,
                  ),
                  CollectionView.world => StickerBook(
                    worlds: worlds,
                    discovered: discovered,
                    unseen: _unseen,
                    localeCode: localeCode,
                    initialPage: _bookPage.clamp(0, worlds.length - 1),
                    onPageChanged: (i) => _bookPage = i,
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _onViewChanged(CollectionView v) {
    setState(() => _view = v);
    if (v == CollectionView.badge) {
      unawaited(_openBadges());
    }
  }

  /// 「しょうごう」入場時: クリア外で満たしたバッチ（図鑑コンプ/レア等）も評価して
  /// 取得を確定し、未読スナップショットで NEW を出しつつ永続側を既読化する。
  Future<void> _openBadges() async {
    try {
      await evaluateAndGrantBadges(ref);
    } on Object catch (e) {
      debugPrint('badge grant on open failed: $e');
    }
    if (!mounted) return;
    final repo = ref.read(badgeRepositoryProvider);
    setState(() => _badgeUnseenSnapshot = repo.unseen());
    unawaited(
      repo.markSeen(_badgeUnseenSnapshot).catchError((Object e) {
        debugPrint('badge markSeen failed: $e');
      }),
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
