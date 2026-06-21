import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'createSlot stores the chosen avatar and unlocks first scene for that slot',
    () async {
      final c = await _container();
      await c
          .read(saveSlotControllerProvider.notifier)
          .createSlot('slot1', '🦊');

      final state = c.read(saveSlotControllerProvider);
      expect(state.containsKey('slot1'), isTrue);
      expect(state['slot1'], '🦊'); // 選んだ絵文字がアバターとして保持される
      c.read(activeSlotProvider.notifier).select('slot1');
      // 3 モードとも scene01 が初期解放される（最初からどのモードも選べる）。
      final progress = c.read(progressRepositoryProvider);
      for (final mode in GameMode.values) {
        expect(
          progress.isUnlocked(mode, 'scene01'),
          isTrue,
          reason: 'scene01 should be unlocked in $mode',
        );
      }
    },
  );

  test('slots have independent progress', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1', '🐶');
    await ctrl.createSlot('slot2', '🐱');

    c.read(activeSlotProvider.notifier).select('slot1');
    await c
        .read(progressRepositoryProvider)
        .markCleared(GameMode.easy, 'scene01');

    c.read(activeSlotProvider.notifier).select('slot1');
    expect(
      c.read(progressRepositoryProvider).isCleared(GameMode.easy, 'scene01'),
      isTrue,
    );
    c.read(activeSlotProvider.notifier).select('slot2');
    expect(
      c.read(progressRepositoryProvider).isCleared(GameMode.easy, 'scene01'),
      isFalse,
    );
  });

  test('resetSlot clears progress, avatar, and uncreates', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1', '🦊');
    await ctrl.resetSlot('slot1');

    expect(c.read(saveSlotControllerProvider).containsKey('slot1'), isFalse);
    final prefs = c.read(sharedPreferencesProvider);
    // 全モードの解放/クリアキーが消えていること（clearAll が全モードを掃除）。
    for (final key in [
      'progress.slot1.unlockedSceneIds',
      'progress.slot1.clearedSceneIds',
      'progress.slot1.normal.unlockedSceneIds',
      'progress.slot1.normal.clearedSceneIds',
      'progress.slot1.hard.unlockedSceneIds',
      'progress.slot1.hardClearedSceneIds',
    ]) {
      expect(
        prefs.getStringList(key),
        isNull,
        reason: '$key should be cleared',
      );
    }
    expect(c.read(saveSlotRepositoryProvider).avatarOf('slot1'), isNull);
  });

  test('changeAvatar swaps the avatar without touching progress', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1', '🐶');

    c.read(activeSlotProvider.notifier).select('slot1');
    await c
        .read(progressRepositoryProvider)
        .markCleared(GameMode.easy, 'scene01');

    await ctrl.changeAvatar('slot1', '🦊');

    // アバターだけ差し替わる。
    expect(c.read(saveSlotControllerProvider)['slot1'], '🦊');
    expect(c.read(saveSlotRepositoryProvider).avatarOf('slot1'), '🦊');
    // 進捗（クリア状態）は保持される。
    c.read(activeSlotProvider.notifier).select('slot1');
    expect(
      c.read(progressRepositoryProvider).isCleared(GameMode.easy, 'scene01'),
      isTrue,
    );
  });

  test('changeAvatar is a no-op for an uncreated slot', () async {
    final c = await _container();
    await c
        .read(saveSlotControllerProvider.notifier)
        .changeAvatar('slot2', '🦊');

    expect(c.read(saveSlotControllerProvider).containsKey('slot2'), isFalse);
    expect(c.read(saveSlotRepositoryProvider).avatarOf('slot2'), isNull);
  });

  test('build falls back to default avatar for legacy slots', () async {
    // この機能以前に作られた（アバター未保存の）スロットを再現。
    SharedPreferences.setMockInitialValues({
      'save.createdSlotIds': ['slot1'],
    });
    final c = await _container();

    final state = c.read(saveSlotControllerProvider);
    expect(state.containsKey('slot1'), isTrue);
    expect(state['slot1'], kDefaultAvatar);
  });

  test('enterFreeMode unlocks all catalog scenes in free namespace', () async {
    final c = await _container();
    await c.read(saveSlotControllerProvider.notifier).enterFreeMode();

    final prefs = c.read(sharedPreferencesProvider);
    final freeRepo = ProgressRepository(prefs, kFreeModeSlotId);
    for (final entry in kSceneCatalog) {
      for (final mode in GameMode.values) {
        expect(
          freeRepo.isUnlocked(mode, entry.id),
          isTrue,
          reason: '${entry.id} should be unlocked in free mode ($mode)',
        );
      }
    }
  });

  test('enterFreeMode does not affect real slots', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1', '🐶');
    await ctrl.enterFreeMode();

    c.read(activeSlotProvider.notifier).select('slot1');
    final progress = c.read(progressRepositoryProvider);
    expect(progress.isUnlocked(GameMode.easy, 'scene01'), isTrue);
    expect(progress.isUnlocked(GameMode.easy, 'scene09'), isFalse);
  });
}
