import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 未発見の宝のシルエット。明るい背景に埋もれないよう、単色グレーではなく
/// 「上＝薄いグレー → 下＝濃いグレー」の縦グラデを ShaderMask で焼き込む。
/// 下側を濃く・不透明側へ寄せることで、明背景でも輪郭のコントラストが立つ。
/// シルエットの形は発見後のリッチ SVG と同一形状（SVG のアルファを使う）。
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
    // ShaderMask は描画ごとに saveLayer を伴う。宝は静的なので RepaintBoundary で
    // ラスタをキャッシュし、ズーム/パンや近くのループアニメ再描画の影響を切り離す
    // （_FoundGlow / HintGlow と同じ方針）。
    return RepaintBoundary(
      child: ShaderMask(
        shaderCallback: grayGradient.createShader,
        blendMode: BlendMode.srcIn,
        // srcIn は child の不透明部分をグラデで置き換える（色は無視・アルファ形状を使う）。
        // リッチ SVG があればその形状を、無ければ Material アイコンをシルエット化する。
        child: hasTreasureSvg(iconId)
            ? SvgPicture.asset(treasureSvgAsset(iconId), fit: BoxFit.contain)
            : Icon(targetIcon(iconId), color: Colors.white),
      ),
    );
  }
}
