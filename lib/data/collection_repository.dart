import 'package:shared_preferences/shared_preferences.dart';

/// 「見つけた宝」を永続化する図鑑（コレクション）の窓口。セーブスロット単位で
/// 名前空間化する（`collection.<slot>.discovered`）。
///
/// 収集の単位は **ワールド × 宝アイコン**（`sceneId:iconId`）。同じアイコンでも
/// シーンが違えば別エントリで、「どのワールドで何を見つけたか」を図鑑に残す。
/// モード非依存（Easy/Normal/Hard のどれで見つけても 1 度きり記録する）。
class CollectionRepository {
  CollectionRepository(this._prefs, this._slotId);

  final SharedPreferences _prefs;
  final String _slotId;

  String get _key => 'collection.$_slotId.discovered';

  /// 永続化エントリのキー（`sceneId:iconId`）。
  static String entryKey(String sceneId, String iconId) => '$sceneId:$iconId';

  /// 収集済みエントリ（`sceneId:iconId`）の集合。
  Set<String> discovered() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  bool isDiscovered(String sceneId, String iconId) =>
      discovered().contains(entryKey(sceneId, iconId));

  /// 宝の発見を記録する。新規に記録したら true、既に記録済みなら false
  /// （= 初発見の判定に使える。例: new! バッジ）。
  Future<bool> record(String sceneId, String iconId) async {
    final set = discovered();
    final added = set.add(entryKey(sceneId, iconId));
    if (added) {
      await _prefs.setStringList(_key, set.toList());
    }
    return added;
  }
}
