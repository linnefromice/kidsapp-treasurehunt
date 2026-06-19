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
/// [hiddenIds] はハードモードの点滅で「今まさに消えている」宝の集合で、
/// [foundIds] と同様に当たり判定から除外する（消失中はタップしても無反応＝罰なし）。
String? findHitTargetId({
  required Offset scenePoint,
  required Size sceneSize,
  required List<FindTarget> targets,
  required Set<String> foundIds,
  double scale = kTreasureDisplayScale,
  Set<String> hiddenIds = const {},
}) {
  if (sceneSize.width <= 0 || sceneSize.height <= 0) {
    return null;
  }
  final normalized = Offset(
    scenePoint.dx / sceneSize.width,
    scenePoint.dy / sceneSize.height,
  );
  for (final target in targets) {
    if (foundIds.contains(target.id) || hiddenIds.contains(target.id)) {
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

/// [scenePoint] が [hiddenIds]（点滅で消失中の宝）のいずれかの表示矩形内にあるか。
/// 表示と同じ [scale] で判定する。消失中の宝をタップしたとき空振り（ミスバブル）
/// 扱いにせず「無反応」にするために使う（失敗を罰しない）。空の場所のタップとは区別する。
bool isPointOnHiddenTarget({
  required Offset scenePoint,
  required Size sceneSize,
  required List<FindTarget> targets,
  required Set<String> hiddenIds,
  double scale = kTreasureDisplayScale,
}) {
  if (hiddenIds.isEmpty || sceneSize.width <= 0 || sceneSize.height <= 0) {
    return false;
  }
  final normalized = Offset(
    scenePoint.dx / sceneSize.width,
    scenePoint.dy / sceneSize.height,
  );
  for (final target in targets) {
    if (!hiddenIds.contains(target.id)) {
      continue;
    }
    if (scaledTreasureRect(
      target.normalizedRect,
      scale: scale,
    ).contains(normalized)) {
      return true;
    }
  }
  return false;
}

// ──────────────────────────────────────────
// ハードモードの宝点滅（消える/現れる）
// 描画（不透明度）と当たり判定（見えている＝押せる）を同じ純関数で駆動する。
// ──────────────────────────────────────────

/// 未発見の宝が 1 回「消えて現れる」周期の長さ（やさしめ）。
const Duration kBlinkCyclePeriod = Duration(milliseconds: 4000);

/// この不透明度以上のとき「見えている」とみなし、当たり判定を有効にする境界。
const double kBlinkVisibleThreshold = 0.5;

// 1 周期内のフェーズ境界（やさしめ: 大半は可視・消失は短く緩やか）。
const double _kBlinkVisibleUntil = 0.70; // [0,        0.70) 完全可視
const double _kBlinkFadeOutUntil = 0.78; // [0.70, 0.78) フェードアウト
const double _kBlinkHiddenUntil = 0.92; //  [0.78, 0.92) 完全消失
//                                          [0.92, 1.00) フェードイン

/// ターゲット [slot]（0..count-1 の安定インデックス）の、共有クロック [clock]
/// （0.0–1.0, 周期内の位置）における表示不透明度（0.0–1.0）。
/// 各ターゲットは [count] に応じて位相をずらし、全宝が同時に消えないようにする。
double treasureBlinkOpacity({
  required int slot,
  required int count,
  required double clock,
}) {
  final offset = count <= 0 ? 0.0 : slot / count;
  final p = (clock + offset) % 1.0;
  if (p < _kBlinkVisibleUntil) {
    return 1.0;
  }
  if (p < _kBlinkFadeOutUntil) {
    return 1.0 -
        (p - _kBlinkVisibleUntil) / (_kBlinkFadeOutUntil - _kBlinkVisibleUntil);
  }
  if (p < _kBlinkHiddenUntil) {
    return 0.0;
  }
  return (p - _kBlinkHiddenUntil) / (1.0 - _kBlinkHiddenUntil);
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
