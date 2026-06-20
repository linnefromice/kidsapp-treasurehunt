import 'package:shared_preferences/shared_preferences.dart';

/// 設定(表示言語・なぞりトレイルの色)の永続化窓口。
///
/// いずれも全スロット共通の単一設定として扱う。data 層は features に依存しない
/// よう、既定値はここでは生の文字列で持つ（localeCode の 'ja' と同じ方針）。
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'settings.locale';
  static const _trailColorKey = 'settings.trailColor';

  /// 既定のトレイル色 id。`TrailColorChoice.fallback.id`（= 'sky'）と同値。
  static const _trailColorDefault = 'sky';

  String localeCode() => _prefs.getString(_localeKey) ?? 'ja';

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  /// なぞりトレイルの色 id。未設定時は既定色 ([_trailColorDefault])。
  /// 未知値の解釈（fallback への倒し込み）は呼び出し側の
  /// `TrailColorChoice.fromId` が担う。
  String trailColorId() =>
      _prefs.getString(_trailColorKey) ?? _trailColorDefault;

  Future<void> setTrailColorId(String id) =>
      _prefs.setString(_trailColorKey, id);
}
