import 'dart:ui';

/// なぞり跡に出すキラキラ粒子トレイルの色。設定で選べる単色 6 色。
///
/// 永続化は [id]（文字列）で行い、未知の値は [fallback] に倒す。
/// 将来「にじ（色相変化）」を足すときは enum に 1 値追加し
/// [resolveTrailColor] に分岐を 1 つ増やすだけで済むよう設計している。
enum TrailColorChoice {
  sky('sky', Color(0xFF42A5F5)),
  pink('pink', Color(0xFFFF6FA5)),
  yellow('yellow', Color(0xFFFFD54F)),
  purple('purple', Color(0xFFAB47BC)),
  orange('orange', Color(0xFFFF9800)),
  white('white', Color(0xFFFFFFFF));

  const TrailColorChoice(this.id, this.baseColor);

  /// 永続化キー兼 i18n サフィックス（`trailColor.<id>`）。
  final String id;

  /// 単色トレイルの基本色。チップのスウォッチ表示にも使う。
  final Color baseColor;

  /// 未設定・未知 id 時の既定色（既存の MissBubble と調和する みずいろ）。
  static const fallback = TrailColorChoice.sky;

  /// 永続値（id 文字列）から復元する。未知・null は [fallback]。
  static TrailColorChoice fromId(String? id) {
    for (final choice in values) {
      if (choice.id == id) return choice;
    }
    return fallback;
  }
}

/// 1 粒ごとの実際の描画色を解決する。
///
/// 現状は単色なので [particleIndex] は未使用だが、にじ実装時に粒子ごとへ
/// 色相を割り当てる拡張点として受け取っておく（呼び出し側は無改修で済む）。
Color resolveTrailColor(TrailColorChoice choice, {required int particleIndex}) {
  return choice.baseColor;
}
