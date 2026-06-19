import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/audio/audio_service.dart';

/// main で実インスタンスに override する。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main',
  );
});

/// 現在選択中のセーブスロット id（未選択は null）。
class ActiveSlotController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String slotId) => state = slotId;
  void deselect() => state = null;
}

final activeSlotProvider = NotifierProvider<ActiveSlotController, String?>(
  ActiveSlotController.new,
);

final saveSlotRepositoryProvider = Provider<SaveSlotRepository>(
  (ref) => SaveSlotRepository(ref.watch(sharedPreferencesProvider)),
);

/// 作成済みスロット（slotId → アバター絵文字）+ 生成/リセットのライフサイクル。
/// キー集合が「作成済みスロット id」、値が選択されたアバター絵文字。
class SaveSlotController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final repo = ref.read(saveSlotRepositoryProvider);
    return {
      for (final id in repo.createdSlotIds())
        id: repo.avatarOf(id) ?? kDefaultAvatar,
    };
  }

  Future<void> createSlot(String slotId, String emoji) async {
    // アバターはキュレーション済みホワイトリストに限る（キッズ安全の不変条件）。
    assert(
      kAvatarEmojis.contains(emoji),
      'emoji "$emoji" is not in kAvatarEmojis',
    );
    final repo = ref.read(saveSlotRepositoryProvider);
    await repo.markCreated(slotId);
    await repo.setAvatar(slotId, emoji);
    await ProgressRepository(
      ref.read(sharedPreferencesProvider),
      slotId,
    ).ensureInitialUnlock(kFirstSceneId);
    state = {...state, slotId: emoji};
  }

  Future<void> resetSlot(String slotId) async {
    final repo = ref.read(saveSlotRepositoryProvider);
    await repo.removeCreated(slotId);
    await repo.removeAvatar(slotId);
    await ProgressRepository(
      ref.read(sharedPreferencesProvider),
      slotId,
    ).clearAll();
    state = {
      for (final e in state.entries)
        if (e.key != slotId) e.key: e.value,
    };
  }

  /// フリーモード入場: 専用スロットで全カタログシーンを解放する（冪等・毎回再シード）。
  Future<void> enterFreeMode() async {
    await ProgressRepository(
      ref.read(sharedPreferencesProvider),
      kFreeModeSlotId,
    ).unlockAll(kSceneCatalog.map((e) => e.id).toList());
  }
}

final saveSlotControllerProvider =
    NotifierProvider<SaveSlotController, Map<String, String>>(
      SaveSlotController.new,
    );

/// アクティブスロットにスコープした進捗 Repository。既存画面はこれを使うだけでよい。
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final slotId = ref.watch(activeSlotProvider);
  if (slotId == null) {
    throw StateError('No active save slot selected');
  }
  return ProgressRepository(ref.watch(sharedPreferencesProvider), slotId);
});

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
class FoundController extends AutoDisposeFamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String sceneId) => <String>{};

  void markFound(String targetId) {
    if (state.contains(targetId)) return;
    state = {...state, targetId};
  }
}

final foundControllerProvider = NotifierProvider.autoDispose
    .family<FoundController, Set<String>, String>(FoundController.new);
