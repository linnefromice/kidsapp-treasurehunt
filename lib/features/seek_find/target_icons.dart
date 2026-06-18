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
};

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
