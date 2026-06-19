import 'dart:ui';

/// 画面に配置されるダミー宝オブジェクト。ヒット判定に含めない。
class DummyItem {
  const DummyItem({
    required this.id,
    required this.iconId,
    required this.normalizedRect,
    this.scale = 1.0,
  });

  final String id;
  final String iconId;
  final Rect normalizedRect;

  /// 表示サイズの追加倍率（既定 1.0 = 等倍）。Normal / Hard でおとりの大きさを
  /// ものによって変え、探しにくさを出すために使う。ヒット判定対象ではないため
  /// タッチ下限の制約は無く、描画にのみ影響する。JSON 任意フィールド `scale`。
  final double scale;

  factory DummyItem.fromJson(Map<String, dynamic> json) {
    return DummyItem(
      id: json['id'] as String,
      iconId: json['iconId'] as String,
      normalizedRect: Rect.fromLTWH(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
