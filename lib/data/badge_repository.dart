import 'package:shared_preferences/shared_preferences.dart';

/// 獲得した称号バッチを永続化する窓口。セーブスロット単位で名前空間化する
/// （`badges.<slot>.earned`）。一度取ったバッチは sticky（解除されない）。
///
/// 図鑑（CollectionRepository）と同じ「あつめる」設計: 新規取得は unseen（NEW）にも積む。
class BadgeRepository {
  BadgeRepository(this._prefs, this._slotId);

  final SharedPreferences _prefs;
  final String _slotId;

  String get _key => 'badges.$_slotId.earned';
  String get _unseenKey => 'badges.$_slotId.unseen';

  /// 獲得済みバッチ id の集合。
  Set<String> earned() =>
      (_prefs.getStringList(_key) ?? const <String>[]).toSet();

  bool isEarned(String id) => earned().contains(id);

  /// 新規取得したがギャラリーでまだ見ていない（NEW 表示中）バッチ id。
  Set<String> unseen() =>
      (_prefs.getStringList(_unseenKey) ?? const <String>[]).toSet();

  /// 評価結果 [evaluated] のうち未取得分を新規付与する。新規に取得した id 集合を返す
  /// （= 取得演出を出す対象）。何も増えなければ空集合（冪等）。
  Future<Set<String>> grant(Set<String> evaluated) async {
    final current = earned();
    final newly = evaluated.difference(current);
    if (newly.isEmpty) {
      return const <String>{};
    }
    await _prefs.setStringList(_key, (current..addAll(newly)).toList());
    await _prefs.setStringList(_unseenKey, (unseen()..addAll(newly)).toList());
    return newly;
  }

  /// 指定した [ids] を NEW（unseen）から外す（ギャラリーで見たら既読化）。
  Future<void> markSeen(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final remaining = unseen()..removeAll(ids);
    if (remaining.isEmpty) {
      await _prefs.remove(_unseenKey);
    } else {
      await _prefs.setStringList(_unseenKey, remaining.toList());
    }
  }
}
