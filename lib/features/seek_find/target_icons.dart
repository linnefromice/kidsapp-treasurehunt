import 'package:flutter/material.dart';

/// 宝 id → 表示アイコン（プレースホルダ。実アートで差し替え）。
/// 図鑑バーとシーン描画の両方がこれを使い、見た目を一致させる。
const Map<String, IconData> _kTargetIcons = {
  'apple': Icons.apple,
  'duck': Icons.flutter_dash,
  'star': Icons.star,
  'ball': Icons.sports_soccer,
  'flower': Icons.local_florist,
  'heart': Icons.favorite,
  // ダミーアイテム用アイコン
  'leaf': Icons.eco,
  'rabbit': Icons.cruelty_free,
  'bug': Icons.emoji_nature,
  'anchor': Icons.anchor,
  'swimmer': Icons.pool,
  'umbrella': Icons.umbrella,
  'car': Icons.directions_car,
  'key': Icons.key,
};

const Map<String, Color> _kTargetColors = {
  'apple': Color(0xFFE53935),
  'duck': Color(0xFFFDD835),
  'star': Color(0xFFFB8C00),
  'ball': Color(0xFF1E88E5),
  'flower': Color(0xFFD81B60),
  'heart': Color(0xFFE91E63),
  'leaf': Color(0xFF43A047),
  'rabbit': Color(0xFFAB47BC),
  'bug': Color(0xFF00ACC1),
  'anchor': Color(0xFF1565C0),
  'swimmer': Color(0xFF039BE5),
  'umbrella': Color(0xFFFF7043),
  'car': Color(0xFF546E7A),
  'key': Color(0xFFFFB300),
};

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
Color targetColor(String id) => _kTargetColors[id] ?? const Color(0xFF9E9E9E);

/// 既知のアイコン id か。未知の id は targetIcon で `?`（help_outline）に
/// フォールバックし子供が認識できないため、シーン整合性テストで弾く。
bool hasTargetIcon(String id) => _kTargetIcons.containsKey(id);
