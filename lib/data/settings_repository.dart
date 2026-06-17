import 'package:shared_preferences/shared_preferences.dart';

/// 設定(表示言語)の永続化窓口。
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'settings.locale';

  String localeCode() => _prefs.getString(_localeKey) ?? 'ja';

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);
}
