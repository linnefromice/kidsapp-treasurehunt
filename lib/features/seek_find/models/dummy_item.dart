import 'dart:ui';

/// 画面に配置されるダミー宝オブジェクト。ヒット判定に含めない。
class DummyItem {
  const DummyItem({
    required this.id,
    required this.iconId,
    required this.normalizedRect,
  });

  final String id;
  final String iconId;
  final Rect normalizedRect;

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
    );
  }
}
