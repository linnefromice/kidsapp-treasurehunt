import 'package:shared_preferences/shared_preferences.dart';

/// 進捗（解放/クリア）の永続化窓口。セーブスロット単位でキーを名前空間化する。
class ProgressRepository {
  ProgressRepository(this._prefs, this._slotId);

  final SharedPreferences _prefs;
  final String _slotId;

  String get _unlockedKey => 'progress.$_slotId.unlockedSceneIds';
  String get _clearedKey => 'progress.$_slotId.clearedSceneIds';

  List<String> unlockedSceneIds() =>
      _prefs.getStringList(_unlockedKey) ?? const [];
  List<String> clearedSceneIds() =>
      _prefs.getStringList(_clearedKey) ?? const [];

  bool isUnlocked(String sceneId) => unlockedSceneIds().contains(sceneId);
  bool isCleared(String sceneId) => clearedSceneIds().contains(sceneId);

  Future<void> ensureInitialUnlock(String firstSceneId) async {
    if (unlockedSceneIds().isEmpty) {
      await _prefs.setStringList(_unlockedKey, [firstSceneId]);
    }
  }

  Future<void> unlock(String sceneId) async {
    final next = unlockedSceneIds().toSet()..add(sceneId);
    await _prefs.setStringList(_unlockedKey, next.toList());
  }

  /// 渡したシーンをまとめて解放する（フリーモードの全解放に使用・冪等）。
  Future<void> unlockAll(List<String> sceneIds) async {
    final next = unlockedSceneIds().toSet()..addAll(sceneIds);
    await _prefs.setStringList(_unlockedKey, next.toList());
  }

  Future<void> markCleared(String sceneId) async {
    final next = clearedSceneIds().toSet()..add(sceneId);
    await _prefs.setStringList(_clearedKey, next.toList());
  }

  /// このスロットの進捗キーを削除する（リセット用）。
  Future<void> clearAll() async {
    await _prefs.remove(_unlockedKey);
    await _prefs.remove(_clearedKey);
  }
}
