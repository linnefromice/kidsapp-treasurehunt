import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/progress_repository.dart';
import 'data/settings_repository.dart';
import 'features/seek_find/models/scene_def.dart';
import 'shared/audio/audio_service.dart';

/// main で実インスタンスに override する。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main',
  );
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final audioServiceProvider = Provider<AudioService>(
  (ref) => AudioPlayersService(),
);

/// シーン定義の非同期ロード(sceneId ごと)。
final sceneProvider = FutureProvider.family<SceneDef, String>(
  (ref, sceneId) => SceneDef.loadAsset(sceneId),
);

/// 表示言語。初期値は SettingsRepository から。
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.read(settingsRepositoryProvider).localeCode());

  Future<void> setLocale(String code) async {
    await ref.read(settingsRepositoryProvider).setLocaleCode(code);
    state = Locale(code);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

/// シーン内で見つけた宝の id 集合(sceneId ごと)。
class FoundController extends FamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String sceneId) => <String>{};

  void markFound(String targetId) {
    if (state.contains(targetId)) return;
    state = {...state, targetId};
  }
}

final foundControllerProvider =
    NotifierProvider.family<FoundController, Set<String>, String>(
      FoundController.new,
    );
