import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

/// 進捗（解放/クリア）の永続化窓口。セーブスロット単位 ＋ [GameMode] 単位で
/// キーを名前空間化し、難易度ごとに独立した解放・クリアを管理する。
///
/// 既存セーブを保つため Easy はレガシーキーを流用する（移行コード不要）:
/// - 解放:   easy=`progress.<slot>.unlockedSceneIds` /
///           normal=`...normal.unlockedSceneIds` / hard=`...hard.unlockedSceneIds`
/// - クリア: easy=`progress.<slot>.clearedSceneIds` /
///           normal=`...normal.clearedSceneIds` / hard=`...hardClearedSceneIds`
class ProgressRepository {
  ProgressRepository(this._prefs, this._slotId);

  final SharedPreferences _prefs;
  final String _slotId;

  String _unlockedKey(GameMode mode) => switch (mode) {
    GameMode.easy => 'progress.$_slotId.unlockedSceneIds',
    GameMode.normal => 'progress.$_slotId.normal.unlockedSceneIds',
    GameMode.hard => 'progress.$_slotId.hard.unlockedSceneIds',
    GameMode.pro => 'progress.$_slotId.pro.unlockedSceneIds',
  };

  String _clearedKey(GameMode mode) => switch (mode) {
    GameMode.easy => 'progress.$_slotId.clearedSceneIds',
    GameMode.normal => 'progress.$_slotId.normal.clearedSceneIds',
    // 既存セーブ互換のため hard クリアだけ旧キー名を流用する（`hard.` 接頭ではない）。
    // unlock 側は新形式 `hard.unlockedSceneIds` なので、ここの非対称は意図的。
    GameMode.hard => 'progress.$_slotId.hardClearedSceneIds',
    GameMode.pro => 'progress.$_slotId.pro.clearedSceneIds',
  };

  List<String> unlockedSceneIds(GameMode mode) =>
      _prefs.getStringList(_unlockedKey(mode)) ?? const [];

  List<String> clearedSceneIds(GameMode mode) =>
      _prefs.getStringList(_clearedKey(mode)) ?? const [];

  bool isUnlocked(GameMode mode, String sceneId) =>
      unlockedSceneIds(mode).contains(sceneId);

  bool isCleared(GameMode mode, String sceneId) =>
      clearedSceneIds(mode).contains(sceneId);

  /// [sceneIds]（カタログ全シーン）がこのモードで全てクリア済みか。
  /// 空集合は「全クリア」とみなさない（解放条件として不成立）。
  bool isModeFullyCleared(GameMode mode, Iterable<String> sceneIds) {
    final ids = sceneIds.toList(growable: false);
    if (ids.isEmpty) return false;
    final cleared = clearedSceneIds(mode).toSet();
    return ids.every(cleared.contains);
  }

  /// このモードの解放セットが空のときだけ [firstSceneId] を初期解放する（冪等）。
  Future<void> ensureInitialUnlock(GameMode mode, String firstSceneId) async {
    if (unlockedSceneIds(mode).isEmpty) {
      await _prefs.setStringList(_unlockedKey(mode), [firstSceneId]);
    }
  }

  Future<void> unlock(GameMode mode, String sceneId) async {
    final next = unlockedSceneIds(mode).toSet()..add(sceneId);
    await _prefs.setStringList(_unlockedKey(mode), next.toList());
  }

  /// 渡したシーンをまとめて解放する（フリーモードの全解放に使用・冪等）。
  Future<void> unlockAll(GameMode mode, List<String> sceneIds) async {
    final next = unlockedSceneIds(mode).toSet()..addAll(sceneIds);
    await _prefs.setStringList(_unlockedKey(mode), next.toList());
  }

  Future<void> markCleared(GameMode mode, String sceneId) async {
    final next = clearedSceneIds(mode).toSet()..add(sceneId);
    await _prefs.setStringList(_clearedKey(mode), next.toList());
  }

  /// このスロットの進捗キーを全モード分削除する（リセット用）。
  Future<void> clearAll() async {
    for (final mode in GameMode.values) {
      await _prefs.remove(_unlockedKey(mode));
      await _prefs.remove(_clearedKey(mode));
    }
  }
}
