import 'package:flutter/material.dart';

/// 環境粒子の種類。
enum AmbientKind {
  /// ふわっと横に流れる雲。
  drift,

  /// ゆっくり漂う微粒子（花粉・砂塵）。
  mote,

  /// ゆらゆら漂い明滅するホタル。
  firefly,

  /// 下から上へ昇る泡。
  bubble,

  /// 上から下へ降る雪。
  snow,

  /// その場で瞬く星。
  twinkle,
}

/// 1 シーンに重ねる粒子群の設定（不変）。1 シーンに複数重ねられる。
@immutable
class AmbientSpec {
  const AmbientSpec({
    required this.kind,
    required this.count,
    required this.color,
    required this.seed,
  });

  final AmbientKind kind;
  final int count;
  final Color color;

  /// 粒子の初期配置を決める決定論的シード（`Math.random` 非依存・再現可能）。
  final int seed;
}

/// 1 シーンの粒子総数の上限（性能・Kids 規制ガイド H 章）。
const int kAmbientMaxParticlesPerScene = 30;

/// シーン別の環境アニメ設定。未知の id では空（アニメ無し）。
List<AmbientSpec> ambientSpecsFor(String sceneId) => switch (sceneId) {
  'scene01' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 101,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 8,
      color: Color(0xFFFFF6C8),
      seed: 102,
    ),
  ],
  'scene02' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 201,
    ),
  ],
  'scene03' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 14,
      color: Color(0xFFFFFFFF),
      seed: 301,
    ),
  ],
  'scene04' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 401,
    ),
  ],
  'scene05' => const [
    AmbientSpec(
      kind: AmbientKind.firefly,
      count: 7,
      color: Color(0xFFCDEB6B),
      seed: 501,
    ),
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 10,
      color: Color(0xFFFFFDE7),
      seed: 502,
    ),
  ],
  'scene06' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0xB3FFE0B2),
      seed: 601,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 6,
      color: Color(0xFFFFE0B2),
      seed: 602,
    ),
  ],
  'scene07' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 18,
      color: Color(0xFFFFFFFF),
      seed: 701,
    ),
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 1,
      color: Color(0x33B39DDB),
      seed: 702,
    ),
  ],
  'scene08' => const [
    AmbientSpec(
      kind: AmbientKind.bubble,
      count: 14,
      color: Color(0xFFE1F5FE),
      seed: 801,
    ),
  ],
  'scene09' => const [
    AmbientSpec(
      kind: AmbientKind.snow,
      count: 26,
      color: Color(0xFFFFFFFF),
      seed: 901,
    ),
  ],
  'scene10' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 1001,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 8,
      color: Color(0xFFFFF6C8),
      seed: 1002,
    ),
  ],
  'scene11' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 1101,
    ),
  ],
  'scene12' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 12,
      color: Color(0xFFFFFDE7),
      seed: 1201,
    ),
  ],
  'scene13' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 16,
      color: Color(0xFFFFFFFF),
      seed: 1301,
    ),
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0x33AB47BC),
      seed: 1302,
    ),
  ],
  // scene14 まち: ひるまの空に雲が漂う。
  'scene14' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 1401,
    ),
  ],
  // scene15 おかしのくに: ふわふわの光の粒（砂糖のきらめき）。
  'scene15' => const [
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 10,
      color: Color(0xFFFFF6C8),
      seed: 1501,
    ),
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0x66F8BBD0),
      seed: 1502,
    ),
  ],
  // scene16 どうぶつえん: 草地の上を舞う光の粒。
  'scene16' => const [
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 8,
      color: Color(0xFFFFF6C8),
      seed: 1601,
    ),
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0xCCFFFFFF),
      seed: 1602,
    ),
  ],
  // scene17 ゆうえんち: 夕暮れに瞬くイルミネーション。
  'scene17' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 14,
      color: Color(0xFFFFF59D),
      seed: 1701,
    ),
  ],
  // scene18 まちのおしごと: 青空に雲が漂う。
  'scene18' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 1801,
    ),
  ],
  // scene19 みなと: 海の上を漂う雲＋きらめく光の粒。
  'scene19' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0xCCFFFFFF),
      seed: 1901,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 6,
      color: Color(0xFFFFFDE7),
      seed: 1902,
    ),
  ],
  // scene20 こどもべや: 窓から差す光のほこり（やわらかいモート）。
  'scene20' => const [
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 10,
      color: Color(0xFFFFF6C8),
      seed: 2001,
    ),
  ],
  // scene21 スーパー: 明るい店内の光の粒。
  'scene21' => const [
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 8,
      color: Color(0xFFFFFDE7),
      seed: 2101,
    ),
  ],
  _ => const [],
};
