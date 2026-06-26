/// なぞりトレイルの「ブラシ」（粒の形 or 連続ストローク・コスメ #4 / トレイル拡充 #1#2）。
/// 色（[TrailColorChoice]）とは独立。
///
/// 粒タイプ（circle/star/heart/bubble/flower/neon）は指先に粒を散らす。
/// ストロークタイプ（ribbon/comet）は軌跡を 1 本の線で描く（[isStroke]）。
///
/// [circle] は常時。それ以外は**バッチ取得で解放**する収集ブラシ
/// （[unlockBadgeId] = `BadgeKind.name`）。競争ではなく「あつめて使う飾り」。
enum TrailShape {
  circle('circle', null),
  star('star', 'firstClear'),
  heart('heart', 'worldComplete'),
  bubble('bubble', 'firstFind'),
  flower('flower', 'explorer'),
  neon('neon', 'hardAll'),
  ribbon('ribbon', 'normalAll'),
  comet('comet', 'rareAll');

  const TrailShape(this.id, this.unlockBadgeId);

  /// 永続化・参照に使う安定 id。
  final String id;

  /// 解放に必要なバッチ id（`BadgeKind.name`）。null は常時解放。
  final String? unlockBadgeId;

  /// 連続ストローク（線）で描くブラシか。false は粒を散らす。
  bool get isStroke => this == TrailShape.ribbon || this == TrailShape.comet;

  static const fallback = TrailShape.circle;

  /// 未知・null は安全に既定（[circle]）へ倒す。
  static TrailShape fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return fallback;
  }
}
