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
      expect(
        c.read(progressRepositoryProvider).isUnlocked(GameMode.easy, 'scene01'),
        isTrue,
      );
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
    expect(prefs.getStringList('progress.slot1.unlockedSceneIds'), isNull);
    expect(c.read(saveSlotRepositoryProvider).avatarOf('slot1'), isNull);
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
      expect(
        freeRepo.isUnlocked(GameMode.easy, entry.id),
        isTrue,
        reason: '${entry.id} should be unlocked in free mode',
      );
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
