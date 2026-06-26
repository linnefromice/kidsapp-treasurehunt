/// なぞりトレイルの粒の「形」（コスメ・#4）。色（[TrailColorChoice]）とは独立。
///
/// [circle] は常時。ほし/ハートは**バッチ取得で解放**する収集コスメ
/// （[unlockBadgeId] = `BadgeKind.name`）。競争ではなく「あつめて使う飾り」。
enum TrailShape {
  circle('circle', null),
  star('star', 'firstClear'),
  heart('heart', 'worldComplete');

  const TrailShape(this.id, this.unlockBadgeId);

  /// 永続化・参照に使う安定 id。
  final String id;

  /// 解放に必要なバッチ id（`BadgeKind.name`）。null は常時解放。
  final String? unlockBadgeId;

  static const fallback = TrailShape.circle;

  /// 未知・null は安全に既定（[circle]）へ倒す。
  static TrailShape fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return fallback;
  }
}
