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
  // ステージ別テーマ宝/ダミー（scene_*.json で使用・SVG は generator で生成）。
  'fox': Icons.pets,
  'owl': Icons.pets,
  'butterfly': Icons.flutter_dash,
  'bird': Icons.flutter_dash,
  'squirrel': Icons.pets,
  'hedgehog': Icons.pets,
  'crab': Icons.pets,
  'starfish': Icons.star_border,
  'fish': Icons.set_meal,
  'octopus': Icons.pets,
  'seahorse': Icons.pets,
  'jellyfish': Icons.pets,
  'penguin': Icons.pets,
  'camel': Icons.pets,
  'snake': Icons.pets,
  'bee': Icons.pets,
  'firefly': Icons.light_mode,
  'astronaut': Icons.person,
  'mushroom': Icons.local_florist,
  'acorn': Icons.eco,
  'shell': Icons.waves,
  'pinetree': Icons.park,
  'cactus': Icons.local_florist,
  'sun': Icons.wb_sunny,
  'snowman': Icons.ac_unit,
  'sunflower': Icons.local_florist,
  'trafficlight': Icons.traffic,
  'house': Icons.home,
  'comet': Icons.auto_awesome,
  'pyramid': Icons.change_history,
  'planet': Icons.public,
  'snowflake': Icons.ac_unit,
  'rainbow': Icons.looks,
  'flag': Icons.flag,
  'saturn': Icons.public,
  'galaxy': Icons.blur_on,
  'bucket': Icons.toys,
  'balloon': Icons.celebration,
  'bus': Icons.directions_bus,
  'backpack': Icons.backpack,
  'rocket': Icons.rocket_launch,
  'ufo': Icons.blur_circular,
  'mitten': Icons.back_hand,
  'sled': Icons.toys,
  'shield': Icons.shield,
  // めくり露出（A1）用の「かぶせもの」。宝に被せ、タップ発見でめくれて宝が現れる。
  // ステージのイメージに合わせて使い分ける（scene_covers.dart のプール参照）。
  'cover_leaves': Icons.grass,
  'cover_snow': Icons.ac_unit,
  'cover_box': Icons.inventory_2,
  'cover_chest': Icons.cases_rounded,
  'cover_shell': Icons.waves,
  'cover_cloud': Icons.cloud,
  'cover_bush': Icons.park,
  'cover_rock': Icons.terrain,
  'cover_star': Icons.auto_awesome,
  // 低頻度レア宝（C4）専用アイコン。base のターゲット/おとりとは衝突しない。
  'rare_gem': Icons.diamond,
  'rare_crown': Icons.workspace_premium,
  'rare_medal': Icons.military_tech,
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
  // ステージ別テーマ宝/ダミーの代表色（ヒントグローの発光色にも使う）。
  'fox': Color(0xFFE8590C),
  'owl': Color(0xFF8C5A2B),
  'butterfly': Color(0xFF9C36B5),
  'bird': Color(0xFF1C7ED6),
  'squirrel': Color(0xFFA6713A),
  'hedgehog': Color(0xFF8C5A2B),
  'crab': Color(0xFFC92A2A),
  'starfish': Color(0xFFE8590C),
  'fish': Color(0xFF1971C2),
  'octopus': Color(0xFF9C36B5),
  'seahorse': Color(0xFFE8590C),
  'jellyfish': Color(0xFFE64980),
  'penguin': Color(0xFF212529),
  'camel': Color(0xFFC68A4A),
  'snake': Color(0xFF2F9E44),
  'bee': Color(0xFFF59F00),
  'firefly': Color(0xFF82C91E),
  'astronaut': Color(0xFF1971C2),
  'mushroom': Color(0xFFC92A2A),
  'acorn': Color(0xFF8C5A2B),
  'shell': Color(0xFFE8950C),
  'pinetree': Color(0xFF2B8A3E),
  'cactus': Color(0xFF2F9E44),
  'sun': Color(0xFFF59F00),
  'snowman': Color(0xFF90CAF9),
  'sunflower': Color(0xFFF59F00),
  'trafficlight': Color(0xFF343A40),
  'house': Color(0xFFE8590C),
  'comet': Color(0xFF4DABF7),
  'pyramid': Color(0xFFC68A4A),
  'planet': Color(0xFF6741D9),
  'snowflake': Color(0xFF74C0FC),
  'rainbow': Color(0xFFFF6B6B),
  'flag': Color(0xFFE03131),
  'saturn': Color(0xFFFCC419),
  'galaxy': Color(0xFF9775FA),
  'bucket': Color(0xFF1971C2),
  'balloon': Color(0xFFC92A2A),
  'bus': Color(0xFFF08C00),
  'backpack': Color(0xFFC92A2A),
  'rocket': Color(0xFFFA5252),
  'ufo': Color(0xFF20C997),
  'mitten': Color(0xFFC92A2A),
  'sled': Color(0xFFC92A2A),
  'shield': Color(0xFF1971C2),
  // かぶせもの（自然物っぽい色・ヒントグローの発光色にも使う）。
  'cover_leaves': Color(0xFF558B2F),
  'cover_snow': Color(0xFF90CAF9),
  'cover_box': Color(0xFF8D6E63),
  'cover_chest': Color(0xFF9A6633),
  'cover_shell': Color(0xFFF06595),
  'cover_cloud': Color(0xFF90CAF9),
  'cover_bush': Color(0xFF2B8A3E),
  'cover_rock': Color(0xFF868E96),
  'cover_star': Color(0xFFF59F00),
  // レア宝（きらびやかな色）。
  'rare_gem': Color(0xFF00BCD4),
  'rare_crown': Color(0xFFFFC107),
  'rare_medal': Color(0xFFFF7043),
};

/// おとり（decoy）として使えるアイコンのプール。再訪時のおとり抽選（C2）で、
/// ここからランダムに引き直す。ターゲット用（apple/duck/star/ball/flower/heart）・
/// カバー用（cover_*）・レア用（rare_*）は除外してある（整合性のため）。
const List<String> kDecoyIconPool = [
  'leaf', 'rabbit', 'bug', 'anchor', 'swimmer', 'umbrella', 'car', 'key', //
  'cake', 'gift', 'gem', 'music', 'cloud', 'moon', 'icecream', 'cookie', //
  'pizza', 'bell', 'lightbulb', 'cat', 'sailboat', 'crown', 'fire', 'kite', //
];

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
Color targetColor(String id) => _kTargetColors[id] ?? const Color(0xFF9E9E9E);

/// 既知のアイコン id か。未知の id は targetIcon で `?`（help_outline）に
/// フォールバックし子供が認識できないため、シーン整合性テストで弾く。
bool hasTargetIcon(String id) => _kTargetIcons.containsKey(id);

/// 全宝アイコン id（描画対象・整合性テスト用）。`_kTargetIcons` のキー全件。
/// 各 id には `assets/treasure_icons/<id>.svg` が 1:1 で対応する
/// （ドリフトは treasure_icons_assets_test で検出する）。
List<String> get kAllTreasureIconIds =>
    List<String>.unmodifiable(_kTargetIcons.keys);

/// 宝アイコンの SVG アセットパス（`assets/treasure_icons/<id>.svg`）。
String treasureSvgAsset(String id) => 'assets/treasure_icons/$id.svg';

/// 高解像度ヒーロー PNG のアセットパス（`assets/treasure_icons_hd/<id>.png`）。
/// 大きく主役で見せる山場（レアリビール等）向けのリッチ版。
String treasurePngAsset(String id) => 'assets/treasure_icons_hd/$id.png';

/// PNG ヒーローアートで描画する id（`kHeroPngIcons` に登録した分だけ PNG 優先）。
/// 未登録は SVG のまま。差し替えは「PNG を置く＋ここに id を足す」の 2 ステップ。
/// 詳細は docs/treasure-art-svg-vs-png.md。
///
/// 現在は空（=全て SVG 描画）。レア3種の初期スタンドインは SVG を qlmanage で
/// ラスタライズしたもので **背景が白に焼き込まれていた**（1-bit alpha）ため、
/// 図鑑「とくべつ」等で白い四角として出る不備があり外した。真の透過 PNG
/// （AI/3D 書き出し）を assets/treasure_icons_hd/ に置いたら id をここへ足して再有効化する。
const Set<String> kHeroPngIcons = <String>{};

/// この id を PNG ヒーローアートで描画するか。
bool hasHeroPng(String id) => kHeroPngIcons.contains(id);

/// この id に対応するリッチ SVG アセットが同梱されているか。
/// 既知アイコン（`_kTargetIcons` の全 id）には 1:1 で SVG を用意している。
/// 未知 id（'mystery' 等のフォールバック）は SVG が無く Material アイコンへ退避する。
bool hasTreasureSvg(String id) => _kTargetIcons.containsKey(id);
