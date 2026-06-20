import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/audio/audio_service.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

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
    // 3 モードとも最初から選べるよう、各モードの初期解放（scene01）をシードする。
    final progress = ProgressRepository(
      ref.read(sharedPreferencesProvider),
      slotId,
    );
    for (final mode in GameMode.values) {
      await progress.ensureInitialUnlock(mode, kFirstSceneId);
    }
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

  /// フリーモード入場: 専用スロットで全カタログシーンを全モード解放する
  /// （冪等・毎回再シード）。
  Future<void> enterFreeMode() async {
    final progress = ProgressRepository(
      ref.read(sharedPreferencesProvider),
      kFreeModeSlotId,
    );
    final allIds = kSceneCatalog.map((e) => e.id).toList();
    for (final mode in GameMode.values) {
      await progress.unlockAll(mode, allIds);
    }
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

/// なぞりトレイルの設定（スタイル + 単色 + にじ3色）。
/// 初期値は SettingsRepository から。全スロット共通。
class TrailSettingController extends Notifier<TrailSetting> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  TrailSetting build() => TrailSetting.fromPersisted(
    styleId: _repo.trailStyleId(),
    solidId: _repo.trailColorId(),
    colors3Csv: _repo.trailColors3Csv(),
  );

  Future<void> selectStyle(TrailStyle style) async {
    await _repo.setTrailStyleId(style.id);
    state = state.copyWith(style: style);
  }

  Future<void> selectSolid(TrailColorChoice choice) async {
    await _repo.setTrailColorId(choice.id);
    state = state.copyWith(solidColor: choice);
  }

  Future<void> selectThreeColorAt(int index, TrailColorChoice choice) async {
    final next = state.withThreeColorAt(index, choice);
    await _repo.setTrailColors3Csv(next.threeColorsCsv);
    state = next;
  }
}

final trailSettingControllerProvider =
    NotifierProvider<TrailSettingController, TrailSetting>(
      TrailSettingController.new,
    );

/// 進捗を見て、満たした解放要件のトレイルスタイルをグローバルに解放する
/// （sticky・端末ぜんたい・一度立てたら戻さない）。クリア確定時とスタイル一覧
/// 参照時の双方から呼べるよう副作用（永続化）だけを行う。
Future<void> syncTrailUnlocks(
  ProgressRepository progress,
  SettingsRepository settings,
) async {
  final sceneIds = kSceneCatalog.map((e) => e.id).toList(growable: false);
  for (final style in TrailStyle.values) {
    final mode = style.unlockRequirement;
    if (mode == null) continue; // 常時解放（solid）
    if (settings.trailStyleUnlocked(style.id)) continue; // 既に解放済み
    if (progress.isModeFullyCleared(mode, sceneIds)) {
      await settings.setTrailStyleUnlocked(style.id);
    }
  }
}

/// 現在使えるトレイルスタイルの集合（UI の真実源）。
///
/// 各スタイルは「永続フラグ（端末ぜんたい・sticky） OR アクティブスロットの
/// live 進捗が全クリア」なら解放扱い。後者は既存の 100% セーブを開いた瞬間に
/// 救済するためで、検出時に [syncTrailUnlocks] で sticky 永続化もしておく。
final unlockedTrailStylesProvider = Provider<Set<TrailStyle>>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final slotId = ref.watch(activeSlotProvider);
  final progress = slotId == null
      ? null
      : ProgressRepository(ref.watch(sharedPreferencesProvider), slotId);

  // live 進捗で新たに解放された分を sticky に焼き込む（表示は下の OR で即時に正しい）。
  if (progress != null) {
    unawaited(syncTrailUnlocks(progress, settings));
  }

  final sceneIds = kSceneCatalog.map((e) => e.id).toList(growable: false);
  return {
    for (final style in TrailStyle.values)
      if (_isStyleUnlocked(style, settings, progress, sceneIds)) style,
  };
});

bool _isStyleUnlocked(
  TrailStyle style,
  SettingsRepository settings,
  ProgressRepository? progress,
  List<String> sceneIds,
) {
  final mode = style.unlockRequirement;
  if (mode == null) return true; // 常時解放（solid）
  if (settings.trailStyleUnlocked(style.id)) return true; // 永続フラグ
  // フラグ未設定でも、現スロットが全クリアなら即時解放（既存セーブ救済）。
  return progress?.isModeFullyCleared(mode, sceneIds) ?? false;
}

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
