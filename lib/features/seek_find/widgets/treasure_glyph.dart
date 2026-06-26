import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';

/// 宝グリフの統一描画。
/// - 発見済み（[found]=true）= フルカラーのリッチ SVG アート。
/// - 未発見（[found]=false）= グレーのシルエット（[UnfoundTreasureIcon]）。
///
/// SVG を同梱していない id（'mystery' 等のフォールバック）は Material アイコンへ
/// 退避する。サイズは親の制約に従う（`FittedBox` や `SizedBox` の中に置く想定）。
class TreasureGlyph extends StatelessWidget {
  const TreasureGlyph({super.key, required this.iconId, required this.found});

  final String iconId;
  final bool found;

  @override
  Widget build(BuildContext context) {
    if (!found) return UnfoundTreasureIcon(iconId: iconId);
    // 山場向けリッチ版（PNG ヒーローアート）を登録した id は PNG 優先。
    // 未登録は SVG、SVG も無ければ Material アイコンへ退避。
    if (hasHeroPng(iconId)) {
      return Image.asset(treasurePngAsset(iconId), fit: BoxFit.contain);
    }
    if (!hasTreasureSvg(iconId)) {
      return Icon(targetIcon(iconId), color: targetColor(iconId));
    }
    return SvgPicture.asset(treasureSvgAsset(iconId), fit: BoxFit.contain);
  }
}
