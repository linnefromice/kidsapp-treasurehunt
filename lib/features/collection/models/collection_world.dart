/// 図鑑（コレクション）画面の 1 ワールド分のメタデータ。
/// 1 シーン（ワールド）と、そのシーンに登場する宝アイコン（重複なし・初出順）。
class CollectionWorld {
  const CollectionWorld({
    required this.sceneId,
    required this.titleKey,
    required this.iconIds,
  });

  final String sceneId;
  final String titleKey;

  /// そのワールドで集められる宝アイコン（重複なし・登場順）。
  final List<String> iconIds;
}
