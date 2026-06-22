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
  // ハードモード専用デコイ用アイコン（既存の宝/ダミーと形が被らない新規アイコン群。
  // どのシーンでも target/dummy として未使用なので整合性不変条件を破らない）。
  'cake': Icons.cake,
  'gift': Icons.card_giftcard,
  'gem': Icons.diamond,
  'music': Icons.music_note,
  'cloud': Icons.cloud,
  'moon': Icons.bedtime,
  'icecream': Icons.icecream,
  'cookie': Icons.cookie,
  'pizza': Icons.local_pizza,
  'bell': Icons.notifications,
  'lightbulb': Icons.lightbulb,
  'cat': Icons.pets,
  'sailboat': Icons.sailing,
  'crown': Icons.emoji_events,
  'fire': Icons.local_fire_department,
  'kite': Icons.toys,
  // めくり露出（A1）用の「かぶせもの」。宝に被せ、タップ発見でめくれて宝が現れる。
  'cover_leaves': Icons.grass,
  'cover_snow': Icons.ac_unit,
  'cover_box': Icons.inventory_2,
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
  // ハードモード専用デコイ用カラー。
  'cake': Color(0xFFEC407A),
  'gift': Color(0xFFD32F2F),
  'gem': Color(0xFF26C6DA),
  'music': Color(0xFF7E57C2),
  'cloud': Color(0xFF42A5F5),
  'moon': Color(0xFF5C6BC0),
  'icecream': Color(0xFFF06292),
  'cookie': Color(0xFF8D6E63),
  'pizza': Color(0xFFFFA726),
  'bell': Color(0xFFFFCA28),
  'lightbulb': Color(0xFFFBC02D),
  'cat': Color(0xFF6D4C41),
  'sailboat': Color(0xFF0277BD),
  'crown': Color(0xFFFFD54F),
  'fire': Color(0xFFF4511E),
  'kite': Color(0xFF00897B),
  // かぶせもの（自然物っぽい色）。
  'cover_leaves': Color(0xFF558B2F),
  'cover_snow': Color(0xFF90CAF9),
  'cover_box': Color(0xFF8D6E63),
};

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
Color targetColor(String id) => _kTargetColors[id] ?? const Color(0xFF9E9E9E);

/// 既知のアイコン id か。未知の id は targetIcon で `?`（help_outline）に
/// フォールバックし子供が認識できないため、シーン整合性テストで弾く。
bool hasTargetIcon(String id) => _kTargetIcons.containsKey(id);
