import 'dart:math';
import 'dart:ui';

import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';

/// シーン座標 [scenePoint](GestureDetector の localPosition)を正規化し、
/// まだ見つかっていない最初のヒット対象 id を返す。空振りは null。
String? findHitTargetId({
  required Offset scenePoint,
  required Size sceneSize,
  required List<FindTarget> targets,
  required Set<String> foundIds,
}) {
  if (sceneSize.width <= 0 || sceneSize.height <= 0) {
    return null;
  }
  final normalized = Offset(
    scenePoint.dx / sceneSize.width,
    scenePoint.dy / sceneSize.height,
  );
  for (final target in targets) {
    if (foundIds.contains(target.id)) {
      continue;
    }
    if (target.normalizedRect.contains(normalized)) {
      return target.id;
    }
  }
  return null;
}

/// まだ見つかっていない宝の中からランダムに 1 つ選び、ヒント表示用の id を返す。
/// 未発見の対象が無い（全て発見済み）場合は null。
String? pickHintTargetId({
  required List<FindTarget> targets,
  required Set<String> foundIds,
  required Random random,
}) {
  final unfound = targets
      .where((t) => !foundIds.contains(t.id))
      .toList(growable: false);
  if (unfound.isEmpty) {
    return null;
  }
  return unfound[random.nextInt(unfound.length)].id;
}
