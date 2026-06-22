import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';

/// 図鑑（コレクション）全体の収集プログレス。
class CollectionProgress {
  const CollectionProgress({required this.found, required this.total});

  final int found;
  final int total;

  /// 全ワールドの全アイコンを集めきったか。
  bool get isComplete => total > 0 && found >= total;
}

/// [worlds]（図鑑カタログ）に対し [discovered]（`sceneId:iconId` 集合）が
/// どれだけ埋まっているかを数える純関数。カタログに無いエントリは数えない。
CollectionProgress collectionProgressOf(
  List<CollectionWorld> worlds,
  Set<String> discovered,
) {
  var total = 0;
  var found = 0;
  for (final w in worlds) {
    total += w.iconIds.length;
    for (final iconId in w.iconIds) {
      if (discovered.contains(
        CollectionRepository.entryKey(w.sceneId, iconId),
      )) {
        found++;
      }
    }
  }
  return CollectionProgress(found: found, total: total);
}
