import 'dart:ui';

/// 隠し宝1つ。座標は 0.0〜1.0 の正規化値で持つ。
class FindTarget {
  const FindTarget({
    required this.id,
    required this.iconId,
    required this.labelKey,
    required this.normalizedRect,
  });

  final String id;

  /// 表示アイコンの識別子。複数の宝が同じアイコンを共有できる（例: heart_1, heart_2 → iconId: heart）。
  final String iconId;
  final String labelKey;
  final Rect normalizedRect;

  factory FindTarget.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return FindTarget(
      id: id,
      // Fallback to id for backward compatibility with JSON that doesn't have iconId yet.
      iconId: (json['iconId'] as String?) ?? id,
      labelKey: json['labelKey'] as String,
      normalizedRect: Rect.fromLTWH(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
    );
  }
}
