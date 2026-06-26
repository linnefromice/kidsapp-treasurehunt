import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kidsapp_treasurehunt/features/badges/badge_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/collection_logic.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

/// 既存の進捗/図鑑データから [BadgeInputs]（事実フラグ）を組み立てる。
/// 図鑑カタログ（ワールド）が必要なので非同期。
Future<BadgeInputs> buildBadgeInputs(WidgetRef ref) async {
  final progress = ref.read(progressRepositoryProvider);
  final discovered = ref.read(collectionRepositoryProvider).discovered();
  final worlds = await ref.read(collectionCatalogProvider.future);

  final sceneIds = kSceneCatalog
      .where((e) => e.hasScene)
      .map((e) => e.id)
      .toList(growable: false);

  // ワールドごとの収集状況。
  bool worldComplete(CollectionWorld w) =>
      w.iconIds.isNotEmpty &&
      w.iconIds.every(
        (ic) => discovered.contains(
          // 図鑑エントリは `sceneId:iconId`。
          '${w.sceneId}:$ic',
        ),
      );
  bool worldVisited(CollectionWorld w) =>
      discovered.any((e) => e.startsWith('${w.sceneId}:'));

  // レア宝（base カタログ外）。`sceneId:iconId` の iconId 部分で判定し種類を畳む。
  final rareFound = discovered
      .map((e) => e.substring(e.indexOf(':') + 1))
      .where(isRareIcon)
      .toSet();

  final progressOf = collectionProgressOf(worlds, discovered);

  return BadgeInputs(
    anyDiscovered: discovered.isNotEmpty,
    anyCleared: GameMode.values.any(
      (m) => progress.clearedSceneIds(m).isNotEmpty,
    ),
    anyWorldComplete: worlds.any(worldComplete),
    easyAllCleared: progress.isModeFullyCleared(GameMode.easy, sceneIds),
    normalAllCleared: progress.isModeFullyCleared(GameMode.normal, sceneIds),
    hardAllCleared: progress.isModeFullyCleared(GameMode.hard, sceneIds),
    collectionComplete: progressOf.isComplete,
    rareFoundCount: rareFound.length,
    rareAllFound: rareFound.length >= kRareIconIds.length,
    allWorldsVisited: worlds.isNotEmpty && worlds.every(worldVisited),
  );
}

/// 現状から獲得すべきバッチを評価し、未取得分を永続化する。
/// 新規に取得したバッチ id 集合を返す（= 取得演出を出す対象）。冪等。
Future<Set<String>> evaluateAndGrantBadges(WidgetRef ref) async {
  // スロット未選択なら何もしない（repository が throw するため事前ガード）。
  if (ref.read(activeSlotProvider) == null) {
    return const <String>{};
  }
  final inputs = await buildBadgeInputs(ref);
  final earned = evaluateBadges(inputs);
  return ref.read(badgeRepositoryProvider).grant(earned);
}
