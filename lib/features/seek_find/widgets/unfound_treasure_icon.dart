import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 未発見の宝のシルエット。明るい背景に埋もれないよう、単色グレーではなく
/// 「上＝薄いグレー → 下＝濃いグレー」の縦グラデを ShaderMask で焼き込む。
/// 下側を濃く・不透明側へ寄せることで、明背景でも輪郭のコントラストが立つ。
class UnfoundTreasureIcon extends StatelessWidget {
  const UnfoundTreasureIcon({super.key, required this.iconId});

  final String iconId;

  // 上は薄く溶け込み、下は濃く沈ませて立体感を出すグレーグラデ。
  static const LinearGradient grayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xB0BDBDBD), // grey.shade400 / alpha ~0.69
      Color(0xDC424242), // grey.shade800 / alpha ~0.86
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: grayGradient.createShader,
      blendMode: BlendMode.srcIn,
      // srcIn はアイコンの不透明部分をグラデで置き換える。child の色は無視されるが
      // アルファ形状は使うため、不透明な白を渡してシルエットを確実に残す。
      child: Icon(targetIcon(iconId), color: Colors.white),
    );
  }
}
