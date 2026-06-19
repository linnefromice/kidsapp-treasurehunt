import 'package:shared_preferences/shared_preferences.dart';

/// 「開始済み（作成済み）」のセーブスロット id 集合を永続化する。
class SaveSlotRepository {
  SaveSlotRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _createdKey = 'save.createdSlotIds';
  static const _avatarPrefix = 'save.avatar.';

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

  /// スロットのアバター絵文字（未設定は null）。
  String? avatarOf(String slotId) => _prefs.getString('$_avatarPrefix$slotId');

  Future<void> setAvatar(String slotId, String emoji) async {
    await _prefs.setString('$_avatarPrefix$slotId', emoji);
  }

  Future<void> removeAvatar(String slotId) async {
    await _prefs.remove('$_avatarPrefix$slotId');
  }
}
