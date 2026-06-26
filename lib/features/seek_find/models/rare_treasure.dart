import 'dart:math';

/// 低頻度レア宝（C4）。再訪/フリーモードで稀に出現する特別な宝。
/// アイコンは **専用**（base のターゲット/おとりと衝突しない `rare_*`）。
class RareTreasure {
  const RareTreasure(this.iconId, this.labelKey);

  final String iconId;
  final String labelKey;
}

/// レア宝のプール。出るときはこの中から 1 つ選ばれる。
const List<RareTreasure> kRareTreasures = [
  RareTreasure('rare_gem', 'rare.gem'),
  RareTreasure('rare_crown', 'rare.crown'),
  RareTreasure('rare_medal', 'rare.medal'),
];

/// レア宝のアイコン id 集合（図鑑の「とくべつ」枠の判定などに使う）。
final Set<String> kRareIconIds = {for (final r in kRareTreasures) r.iconId};

/// 与えられた iconId がレア宝のものか。
bool isRareIcon(String iconId) => kRareIconIds.contains(iconId);

/// レア宝を 1 つ選ぶ。
RareTreasure pickRare(Random random) =>
    kRareTreasures[random.nextInt(kRareTreasures.length)];

/// 各シーン入場時にレア宝が出現する確率（全エントリ＝初回プレイ含む・低頻度で
/// 「また出るかも」のワクワク感）。毎回必ずは出さない。
const double kRareTreasureChance = 0.2;
