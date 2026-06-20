import 'package:flutter/painting.dart';

/// なぞり跡に出すキラキラ粒子トレイルの「色の部品」。設定で選べる単色 6 色。
///
/// 永続化は [id]（文字列）で行い、未知の値は [fallback] に倒す。
/// にじ（[TrailStyle.rainbow3]）の 3 色もこの値から組み立てる。
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

  /// 単色トレイルの基本色。チップ／ドロップダウンのスウォッチ表示にも使う。
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

/// トレイルの描き方（スタイル）。
///
/// - [solid]: 1 色で描く（[TrailSetting.solidColor]）。
/// - [rainbow3]: 選んだ 3 色を粒ごとに循環（[TrailSetting.threeColors]）。
/// - [rainbowFull]: 色相を一周させ、なぞると虹が流れる。
enum TrailStyle {
  solid('solid'),
  rainbow3('rainbow3'),
  rainbowFull('rainbowFull');

  const TrailStyle(this.id);

  /// 永続化キー兼 i18n サフィックス（`trailStyle.<id>`）。
  final String id;

  /// 未設定・未知 id 時の既定スタイル。
  static const fallback = TrailStyle.solid;

  /// 永続値（id 文字列）から復元する。未知・null は [fallback]。
  static TrailStyle fromId(String? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return fallback;
  }
}

/// なぞりトレイルの設定一式（スタイル + 各スタイルのパラメータ）。
///
/// 不変。スタイルを切り替えても単色の色・3 色の組はそれぞれ保持される
/// （永続化キーが独立しているため）。
class TrailSetting {
  /// [threeColors] は常に長さ 3 を前提とする（`fromPersisted` が保証する）。
  const TrailSetting({
    required this.style,
    required this.solidColor,
    required this.threeColors,
  });

  /// 描き方。
  final TrailStyle style;

  /// 単色スタイル時の色。
  final TrailColorChoice solidColor;

  /// にじ3色スタイル時に循環させる 3 色（順序あり・重複可・常に長さ 3）。
  ///
  /// 生成パス（[fromPersisted]/[copyWith]/[withThreeColorAt]）は常に変更不可リスト
  /// （[List.unmodifiable] か `const`）を渡すため、外部から内容を書き換えられない。
  final List<TrailColorChoice> threeColors;

  /// 3 色未設定時の既定（最初の 3 色）。
  static const defaultThreeColors = <TrailColorChoice>[
    TrailColorChoice.sky,
    TrailColorChoice.pink,
    TrailColorChoice.yellow,
  ];

  /// 既定設定（単色・みずいろ）。
  static const fallback = TrailSetting(
    style: TrailStyle.solid,
    solidColor: TrailColorChoice.fallback,
    threeColors: defaultThreeColors,
  );

  /// 永続化された生文字列から復元する。未知・不足は安全に既定へ倒す。
  ///
  /// [colors3Csv] は `id,id,id` 形式。位置ごとに解釈し、要素が不足する位置は
  /// 同じ位置の既定色（[defaultThreeColors]）で補い、3 を超える分は捨てる。
  /// 各 id は [TrailColorChoice.fromId] で解釈する。
  static TrailSetting fromPersisted({
    String? styleId,
    String? solidId,
    String? colors3Csv,
  }) {
    return TrailSetting(
      style: TrailStyle.fromId(styleId),
      solidColor: TrailColorChoice.fromId(solidId),
      threeColors: _parseThreeColors(colors3Csv),
    );
  }

  static List<TrailColorChoice> _parseThreeColors(String? csv) {
    final parts = (csv ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return List<TrailColorChoice>.unmodifiable(
      List<TrailColorChoice>.generate(3, (i) {
        if (i < parts.length) return TrailColorChoice.fromId(parts[i]);
        return defaultThreeColors[i];
      }),
    );
  }

  /// 3 色を CSV（`id,id,id`）へ直列化する。
  String get threeColorsCsv => threeColors.map((c) => c.id).join(',');

  TrailSetting copyWith({
    TrailStyle? style,
    TrailColorChoice? solidColor,
    List<TrailColorChoice>? threeColors,
  }) {
    return TrailSetting(
      style: style ?? this.style,
      solidColor: solidColor ?? this.solidColor,
      threeColors: threeColors != null
          ? List<TrailColorChoice>.unmodifiable(threeColors)
          : this.threeColors,
    );
  }

  /// 3 色のうち [index] 番目を [color] に差し替えた新しい設定を返す。
  TrailSetting withThreeColorAt(int index, TrailColorChoice color) {
    assert(
      index >= 0 && index < threeColors.length,
      'index は 0..${threeColors.length - 1}（受け取った値: $index）',
    );
    final next = [...threeColors];
    next[index] = color;
    return copyWith(threeColors: next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrailSetting &&
        other.style == style &&
        other.solidColor == solidColor &&
        _listEquals(other.threeColors, threeColors);
  }

  @override
  int get hashCode =>
      Object.hash(style, solidColor, Object.hashAll(threeColors));
}

bool _listEquals(List<TrailColorChoice> a, List<TrailColorChoice> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// にじフルの色相ステップ（度）。連続する粒が見分けつつ、なぞる間に一周する。
const double _kRainbowHueStep = 40;

/// 1 粒ごとの実際の描画色を解決する。スタイルの差はここに閉じ込める。
///
/// [particleIndex] は生成順の通し番号。にじ系はこれで色を変化させる。
Color resolveTrailColor(TrailSetting setting, {required int particleIndex}) {
  return switch (setting.style) {
    TrailStyle.solid => setting.solidColor.baseColor,
    TrailStyle.rainbow3 => setting.threeColors[particleIndex % 3].baseColor,
    TrailStyle.rainbowFull => _rainbowHue(particleIndex),
  };
}

Color _rainbowHue(int particleIndex) {
  final hue = (particleIndex * _kRainbowHueStep) % 360;
  return HSVColor.fromAHSV(1, hue, 0.9, 1).toColor();
}
