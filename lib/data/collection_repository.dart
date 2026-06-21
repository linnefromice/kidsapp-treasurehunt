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

  /// 「まだ図鑑で見ていない初発見」（new! バッジ用）の集合キー。
  String get _unseenKey => 'collection.$_slotId.unseen';

  /// 永続化エントリのキー（`sceneId:iconId`）。
  static String entryKey(String sceneId, String iconId) => '$sceneId:$iconId';

  /// 収集済みエントリ（`sceneId:iconId`）の集合。
  Set<String> discovered() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  bool isDiscovered(String sceneId, String iconId) =>
      discovered().contains(entryKey(sceneId, iconId));

  /// 初発見したが図鑑でまだ見ていない（new! 表示中）エントリの集合。
  Set<String> unseen() =>
      (_prefs.getStringList(_unseenKey) ?? const <String>[]).toSet();

  bool isUnseen(String sceneId, String iconId) =>
      unseen().contains(entryKey(sceneId, iconId));

  /// 宝の発見を記録する。新規に記録したら true、既に記録済みなら false
  /// （= 初発見の判定に使える）。初発見は new!（unseen）にも積む。
  Future<bool> record(String sceneId, String iconId) async {
    final entry = entryKey(sceneId, iconId);
    final set = discovered();
    final added = set.add(entry);
    if (added) {
      await _prefs.setStringList(_key, set.toList());
      final pending = unseen()..add(entry);
      await _prefs.setStringList(_unseenKey, pending.toList());
    }
    return added;
  }

  /// 指定した [entries] を new!（unseen）から外す（既読化）。図鑑で表示した分
  /// だけを消すことで、見ている最中に増えた初発見（並行 record）を取りこぼさない。
  Future<void> markSeen(Set<String> entries) async {
    if (entries.isEmpty) {
      return;
    }
    final remaining = unseen()..removeAll(entries);
    if (remaining.isEmpty) {
      await _prefs.remove(_unseenKey);
    } else {
      await _prefs.setStringList(_unseenKey, remaining.toList());
    }
  }
}
