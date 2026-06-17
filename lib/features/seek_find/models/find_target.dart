import 'dart:ui';

/// 隠し宝1つ。座標は 0.0〜1.0 の正規化値で持つ。
class FindTarget {
  const FindTarget({
    required this.id,
    required this.labelKey,
    required this.normalizedRect,
  });

  final String id;
  final String labelKey;
  final Rect normalizedRect;

  factory FindTarget.fromJson(Map<String, dynamic> json) {
    return FindTarget(
      id: json['id'] as String,
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
