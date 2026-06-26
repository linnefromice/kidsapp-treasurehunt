import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// ドリフト検出: PNG ヒーローアートを登録した id（[kHeroPngIcons]）は、
/// 対応する `assets/treasure_icons_hd/<id>.png` が実在して読み込めること。
/// 登録だけして PNG を置き忘れる（実行時に壊れた画像）事故を防ぐ。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('登録した全ヒーロー id に読み込み可能な PNG が存在する', () async {
    for (final id in kHeroPngIcons) {
      final bytes = await rootBundle.load(treasurePngAsset(id));
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '${treasurePngAsset(id)} が空',
      );
    }
  });

  test('ヒーロー登録した id は宝アイコン（SVG/フォールバック）としても既知', () {
    // 未発見シルエットや退避描画のため、SVG 側にも対応がある前提。
    for (final id in kHeroPngIcons) {
      expect(hasTreasureSvg(id), isTrue, reason: '$id の SVG が無い');
    }
  });
}
