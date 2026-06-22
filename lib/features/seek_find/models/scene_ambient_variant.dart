import 'dart:math';

import 'package:flutter/painting.dart';

/// 季節/時間バリアント（C3）。背景の上に半透明ティントを 1 枚重ねて「別版」を作る。
/// 背景 painter は作り替えず、宝の色を保つため**背景の上・宝の下**に重ねる。
/// 再訪/フリー入場時に抽選し、初回（未クリア）は [normal]（素のまま）。
enum SceneAmbientVariant {
  normal(null),
  morning(Color(0x33FFF59D)), // 朝: 淡い黄
  evening(Color(0x40FF7043)), // 夕: オレンジ
  night(Color(0x401A237E)); // 夜: 濃紺

  const SceneAmbientVariant(this.tint);

  /// 背景の上に重ねるティント色（[normal] は null = 重ねない）。
  final Color? tint;
}

/// バリアントを 1 つ抽選する（[normal] を含む一様抽選）。
SceneAmbientVariant pickAmbientVariant(Random random) =>
    SceneAmbientVariant.values[random.nextInt(
      SceneAmbientVariant.values.length,
    )];
