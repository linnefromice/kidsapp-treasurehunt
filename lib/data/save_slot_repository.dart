import 'package:shared_preferences/shared_preferences.dart';

/// 「開始済み（作成済み）」のセーブスロット id 集合を永続化する。
class SaveSlotRepository {
  SaveSlotRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _createdKey = 'save.createdSlotIds';

  List<String> createdSlotIds() =>
      _prefs.getStringList(_createdKey) ?? const [];

  bool isCreated(String slotId) => createdSlotIds().contains(slotId);

  Future<void> markCreated(String slotId) async {
    final next = createdSlotIds().toSet()..add(slotId);
    await _prefs.setStringList(_createdKey, next.toList());
  }

  Future<void> removeCreated(String slotId) async {
    final next = createdSlotIds().toSet()..remove(slotId);
    await _prefs.setStringList(_createdKey, next.toList());
  }
}
