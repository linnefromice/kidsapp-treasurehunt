/// 称号バッチの種類。`name` をそのまま永続化 id に使う（`badges.<slot>.earned`）。
enum BadgeKind {
  firstFind,
  firstClear,
  worldComplete,
  easyAll,
  normalAll,
  hardAll,
  collectionComplete,
  rareFirst,
  rareAll,
  explorer,
}

/// バッチの定義（メタデータ）。判定ロジックは badge_logic.dart に分離する。
///
/// 設計原則: スター/競争/順位/時間ではなく「あつめる記念」。数を競わせない。
/// 表示は絵（[iconId] の SVG）＋音中心、読字非依存（label はあくまで補助）。
class BadgeDef {
  const BadgeDef({
    required this.kind,
    required this.labelKey,
    required this.descKey,
    required this.iconId,
  });

  final BadgeKind kind;

  /// 永続化・参照に使う安定 id（= `kind.name`）。
  String get id => kind.name;

  /// 名前の i18n キー（`badge.<id>`）。
  final String labelKey;

  /// 説明の i18n キー（`badge.<id>.desc`）。
  final String descKey;

  /// バッジ画像の id（`assets/badges/<iconId>.svg`）。
  final String iconId;
}

/// バッチ一覧（ギャラリー表示順）。
const List<BadgeDef> kBadgeCatalog = [
  BadgeDef(
    kind: BadgeKind.firstFind,
    labelKey: 'badge.firstFind',
    descKey: 'badge.firstFind.desc',
    iconId: 'badge_star',
  ),
  BadgeDef(
    kind: BadgeKind.firstClear,
    labelKey: 'badge.firstClear',
    descKey: 'badge.firstClear.desc',
    iconId: 'badge_flag',
  ),
  BadgeDef(
    kind: BadgeKind.worldComplete,
    labelKey: 'badge.worldComplete',
    descKey: 'badge.worldComplete.desc',
    iconId: 'badge_world',
  ),
  BadgeDef(
    kind: BadgeKind.easyAll,
    labelKey: 'badge.easyAll',
    descKey: 'badge.easyAll.desc',
    iconId: 'badge_easy',
  ),
  BadgeDef(
    kind: BadgeKind.normalAll,
    labelKey: 'badge.normalAll',
    descKey: 'badge.normalAll.desc',
    iconId: 'badge_normal',
  ),
  BadgeDef(
    kind: BadgeKind.hardAll,
    labelKey: 'badge.hardAll',
    descKey: 'badge.hardAll.desc',
    iconId: 'badge_hard',
  ),
  BadgeDef(
    kind: BadgeKind.collectionComplete,
    labelKey: 'badge.collectionComplete',
    descKey: 'badge.collectionComplete.desc',
    iconId: 'badge_book',
  ),
  BadgeDef(
    kind: BadgeKind.rareFirst,
    labelKey: 'badge.rareFirst',
    descKey: 'badge.rareFirst.desc',
    iconId: 'badge_gem',
  ),
  BadgeDef(
    kind: BadgeKind.rareAll,
    labelKey: 'badge.rareAll',
    descKey: 'badge.rareAll.desc',
    iconId: 'badge_crown',
  ),
  BadgeDef(
    kind: BadgeKind.explorer,
    labelKey: 'badge.explorer',
    descKey: 'badge.explorer.desc',
    iconId: 'badge_compass',
  ),
];

/// id（`kind.name`）→ [BadgeDef]。
final Map<String, BadgeDef> kBadgeById = {
  for (final b in kBadgeCatalog) b.id: b,
};
