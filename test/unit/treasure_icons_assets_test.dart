import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// ドリフト検出: アイコンマップ（`_kTargetIcons`）の全 id に、登録済みの
/// `assets/treasure_icons/<id>.svg` が実在し読み込めることを保証する。
/// これが無いと、id を追加して SVG を作り忘れた場合に実行時まで（壊れた画像で）
/// 気付けない。`hasTreasureSvg` が前提にしている不変条件をテストで固定する。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('全宝アイコン id に読み込み可能な SVG アセットが存在する', () async {
    expect(kAllTreasureIconIds, isNotEmpty);
    for (final id in kAllTreasureIconIds) {
      expect(
        hasTreasureSvg(id),
        isTrue,
        reason: 'hasTreasureSvg("$id") が false',
      );
      final path = treasureSvgAsset(id);
      final data = await rootBundle.loadString(path);
      expect(data.trim(), isNotEmpty, reason: '$path が空');
      expect(data, contains('<svg'), reason: '$path が SVG として読めない（<svg> 要素なし）');
    }
  });

  test('SVG アセットパスは登録済みディレクトリ配下を指す', () {
    expect(treasureSvgAsset('apple'), 'assets/treasure_icons/apple.svg');
    expect(
      treasureSvgAsset('rare_medal'),
      'assets/treasure_icons/rare_medal.svg',
    );
  });
}
