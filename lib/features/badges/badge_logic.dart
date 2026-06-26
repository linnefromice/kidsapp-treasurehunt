import 'package:kidsapp_treasurehunt/features/badges/models/badge.dart';

/// バッチ判定の入力（既存データから算出した「事実」だけ）。
///
/// 重要（設計原則）: 時間・回数・速さ・順位は **一切含めない**。すべて「やった/やってない」
/// の事実のみ。これによりバッチが競争・スコア化しないことを構造的に担保する。
class BadgeInputs {
  const BadgeInputs({
    required this.anyDiscovered,
    required this.anyCleared,
    required this.anyWorldComplete,
    required this.easyAllCleared,
    required this.normalAllCleared,
    required this.hardAllCleared,
    required this.collectionComplete,
    required this.rareFoundCount,
    required this.rareAllFound,
    required this.allWorldsVisited,
  });

  /// 何か 1 つでも宝を見つけたか。
  final bool anyDiscovered;

  /// 何か 1 ステージでもクリアしたか（モード不問）。
  final bool anyCleared;

  /// どこか 1 ワールドの宝を全部集めたか。
  final bool anyWorldComplete;

  final bool easyAllCleared;
  final bool normalAllCleared;
  final bool hardAllCleared;

  /// 図鑑（ベースカタログ）を 100% 集めたか。
  final bool collectionComplete;

  /// 見つけたレア宝の種類数。
  final int rareFoundCount;

  /// レア宝を全種類見つけたか。
  final bool rareAllFound;

  /// 全プレイ可能ワールドで何かしら見つけたか。
  final bool allWorldsVisited;

  /// 何も達成していない初期状態。
  static const empty = BadgeInputs(
    anyDiscovered: false,
    anyCleared: false,
    anyWorldComplete: false,
    easyAllCleared: false,
    normalAllCleared: false,
    hardAllCleared: false,
    collectionComplete: false,
    rareFoundCount: 0,
    rareAllFound: false,
    allWorldsVisited: false,
  );
}

/// 与えられた事実から、獲得済みバッチ id の集合を返す（純粋関数・冪等）。
Set<String> evaluateBadges(BadgeInputs i) {
  bool earned(BadgeKind kind) => switch (kind) {
    BadgeKind.firstFind => i.anyDiscovered,
    BadgeKind.firstClear => i.anyCleared,
    BadgeKind.worldComplete => i.anyWorldComplete,
    BadgeKind.easyAll => i.easyAllCleared,
    BadgeKind.normalAll => i.normalAllCleared,
    BadgeKind.hardAll => i.hardAllCleared,
    BadgeKind.collectionComplete => i.collectionComplete,
    BadgeKind.rareFirst => i.rareFoundCount >= 1,
    BadgeKind.rareAll => i.rareAllFound,
    BadgeKind.explorer => i.allWorldsVisited,
  };
  return {
    for (final b in kBadgeCatalog)
      if (earned(b.kind)) b.id,
  };
}
