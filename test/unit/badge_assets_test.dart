import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/badges/models/badge.dart';

/// ドリフト検出: カタログの全バッジに、登録済みの `assets/badges/<iconId>.svg` が
/// 実在し読み込めることを保証する（バッジ追加時の SVG 作り忘れを防ぐ）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('全バッジに読み込み可能な SVG アセットが存在する', () async {
    expect(kBadgeCatalog, isNotEmpty);
    for (final b in kBadgeCatalog) {
      final path = badgeSvgAsset(b.iconId);
      final data = await rootBundle.loadString(path);
      expect(data.trim(), isNotEmpty, reason: '$path が空');
      expect(data, contains('<svg'), reason: '$path が SVG として読めない');
    }
  });

  test('バッジ id とアイコン id は一意', () {
    final ids = kBadgeCatalog.map((b) => b.id).toList();
    final icons = kBadgeCatalog.map((b) => b.iconId).toList();
    expect(ids.toSet().length, ids.length);
    expect(icons.toSet().length, icons.length);
  });
}
