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
  static const _trailStyleKey = 'settings.trailStyle';
  static const _trailColors3Key = 'settings.trailColors3';

  /// 既定のトレイル色 id。`TrailColorChoice.fallback.id`（= 'sky'）と同値。
  static const _trailColorDefault = 'sky';

  /// 既定のトレイルスタイル id。`TrailStyle.fallback.id`（= 'solid'）と同値。
  static const _trailStyleDefault = 'solid';

  /// 既定のにじ3色 CSV。`TrailSetting.defaultThreeColors` の id 列と同値。
  static const _trailColors3Default = 'sky,pink,yellow';

  String localeCode() => _prefs.getString(_localeKey) ?? 'ja';

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  /// なぞりトレイルの色 id。未設定時は既定色 ([_trailColorDefault])。
  /// 未知値の解釈（fallback への倒し込み）は呼び出し側の
  /// `TrailColorChoice.fromId` が担う。
  String trailColorId() =>
      _prefs.getString(_trailColorKey) ?? _trailColorDefault;

  Future<void> setTrailColorId(String id) =>
      _prefs.setString(_trailColorKey, id);

  /// なぞりトレイルのスタイル id。未設定時は既定 ([_trailStyleDefault])。
  String trailStyleId() =>
      _prefs.getString(_trailStyleKey) ?? _trailStyleDefault;

  Future<void> setTrailStyleId(String id) =>
      _prefs.setString(_trailStyleKey, id);

  /// にじ3色の id を CSV (`id,id,id`) で保持する。未設定時は既定。
  /// 形式の検証・補完は呼び出し側の `TrailSetting.fromPersisted` が担う。
  String trailColors3Csv() =>
      _prefs.getString(_trailColors3Key) ?? _trailColors3Default;

  Future<void> setTrailColors3Csv(String csv) =>
      _prefs.setString(_trailColors3Key, csv);
}
