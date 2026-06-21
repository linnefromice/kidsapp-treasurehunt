import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
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

  void select(String slotId) {
    state = slotId;
    // 既存の 100% クリア済みセーブも含め、選択時に解放要件を満たすスタイルを
    // sticky 永続化する（端末ぜんたい・戻らない）。フリーモードは markCleared
    // しない＝全クリア扱いにならないため対象外。
    if (slotId == kFreeModeSlotId) return;
    // progressRepositoryProvider は activeSlotProvider を watch するため、ここで
    // read すると循環依存になる。createSlot 等と同じく直接構築する。
    final progress = ProgressRepository(
      ref.read(sharedPreferencesProvider),
      slotId,
    );
    unawaited(syncTrailUnlocks(progress, ref.read(settingsRepositoryProvider)));
  }

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

  /// 作成済みスロットのアバターだけを差し替える（進捗・解放はそのまま）。
  /// 非破壊なので保護者ゲートは不要（子どもの「きせかえ」遊びの一部）。
  Future<void> changeAvatar(String slotId, String emoji) async {
    assert(
      kAvatarEmojis.contains(emoji),
      'emoji "$emoji" is not in kAvatarEmojis',
    );
    // 未作成スロットには無効（白紙は createSlot 経由でのみ作る）。
    if (!state.containsKey(slotId)) return;
    final repo = ref.read(saveSlotRepositoryProvider);
    await repo.setAvatar(slotId, emoji);
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

/// アクティブスロットにスコープした図鑑（コレクション）Repository。
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final slotId = ref.watch(activeSlotProvider);
  if (slotId == null) {
    throw StateError('No active save slot selected');
  }
  return CollectionRepository(ref.watch(sharedPreferencesProvider), slotId);
});

/// 図鑑カタログ: 各プレイ可能シーンの (id, titleKey, 重複なし宝アイコン)。
/// 13 シーンのアセットを読み、図鑑画面のページ構成に使う（静的データ）。
final collectionCatalogProvider = FutureProvider<List<CollectionWorld>>((
  ref,
) async {
  final entries = kSceneCatalog.where((e) => e.hasScene).toList();
  // 13 シーンを並列ロード（順次 await だと合計時間が嵩む）。
  final scenes = await Future.wait(
    entries.map((e) => SceneDef.loadAsset(e.id)),
  );
  return [
    for (var i = 0; i < entries.length; i++)
      CollectionWorld(
        sceneId: entries[i].id,
        titleKey: entries[i].titleKey,
        // 重複なし・登場順を維持（seen で O(1) 判定）。
        iconIds: _distinctInOrder(scenes[i].targets.map((t) => t.iconId)),
      ),
  ];
});

/// 登場順を保ったまま重複を畳む（`Set` 判定で O(n)）。
List<String> _distinctInOrder(Iterable<String> ids) {
  final seen = <String>{};
  final out = <String>[];
  for (final id in ids) {
    if (seen.add(id)) {
      out.add(id);
    }
  }
  return out;
}

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

/// 選択中の難易度（Easy / Normal / Hard）。初期値は SettingsRepository から。
/// 全スロット共通の表示設定として扱い、ナビゲーション・再起動をまたいで保持する。
class GameModeController extends Notifier<GameMode> {
  @override
  GameMode build() => ref.read(settingsRepositoryProvider).gameMode();

  Future<void> select(GameMode mode) async {
    await ref.read(settingsRepositoryProvider).setGameMode(mode);
    state = mode;
  }
}

final gameModeControllerProvider =
    NotifierProvider<GameModeController, GameMode>(GameModeController.new);

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
/// （sticky・端末ぜんたい・一度立てたら戻さない）。クリア確定時（_handleComplete）
/// とスロット選択時（ActiveSlotController.select）の双方から呼ぶ、永続化だけの副作用。
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
/// 副作用のない純粋な導出。各スタイルは「永続フラグ（端末ぜんたい・sticky） OR
/// アクティブスロットの live 進捗が全クリア」なら解放扱い。後者は既存の 100%
/// セーブをそのスロットで開いた瞬間に「見た目だけ」即時解放するため。フラグへの
/// 焼き込み（端末ぜんたい化）は [ActiveSlotController.select] と _handleComplete が担う。
final unlockedTrailStylesProvider = Provider<Set<TrailStyle>>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final slotId = ref.watch(activeSlotProvider);
  final progress = slotId == null
      ? null
      : ProgressRepository(ref.watch(sharedPreferencesProvider), slotId);

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
