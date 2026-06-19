import 'dart:math';
import 'dart:ui';

import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';

/// 宝アイコンを元の正規化 Rect から一律に拡大する表示倍率。
/// 表示（Positioned レイアウト）と当たり判定（[findHitTargetId]）の両方で
/// この同じ値を使うことで「見えている大きさ = 押せる大きさ」を保つ。
const double kTreasureDisplayScale = 1.15;

/// [normalizedRect] を中心を保ったまま [scale] 倍に拡大/縮小する。
/// 既定は [kTreasureDisplayScale]（通常モード）。ハードモードは小さい [scale] を渡す。
/// 端に置かれた宝では結果が [0,1] をわずかに超えうるが、タップ座標は常に
/// シーン内に収まるため当たり判定は安全。
Rect scaledTreasureRect(
  Rect normalizedRect, {
  double scale = kTreasureDisplayScale,
}) => Rect.fromCenter(
  center: normalizedRect.center,
  width: normalizedRect.width * scale,
  height: normalizedRect.height * scale,
);

/// シーン座標 [scenePoint](GestureDetector の localPosition)を正規化し、
/// まだ見つかっていない最初のヒット対象 id を返す。空振りは null。
String? findHitTargetId({
  required Offset scenePoint,
  required Size sceneSize,
  required List<FindTarget> targets,
  required Set<String> foundIds,
  double scale = kTreasureDisplayScale,
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
    // 表示と同じ拡大率で判定し、見た目どおりの当たり判定にする。
    if (scaledTreasureRect(
      target.normalizedRect,
      scale: scale,
    ).contains(normalized)) {
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
