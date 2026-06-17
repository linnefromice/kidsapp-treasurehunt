import 'package:shared_preferences/shared_preferences.dart';

/// 進捗(解放/クリア)の永続化窓口。shared_preferences をここに隠蔽する。
class ProgressRepository {
  ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _unlockedKey = 'progress.unlockedSceneIds';
  static const _clearedKey = 'progress.clearedSceneIds';

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

  Future<void> markCleared(String sceneId) async {
    final next = clearedSceneIds().toSet()..add(sceneId);
    await _prefs.setStringList(_clearedKey, next.toList());
  }
}
