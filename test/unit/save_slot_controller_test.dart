import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

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
    'createSlot marks created and unlocks first scene for that slot',
    () async {
      final c = await _container();
      await c.read(saveSlotControllerProvider.notifier).createSlot('slot1');

      expect(c.read(saveSlotControllerProvider).contains('slot1'), isTrue);
      c.read(activeSlotProvider.notifier).select('slot1');
      expect(c.read(progressRepositoryProvider).isUnlocked('scene01'), isTrue);
    },
  );

  test('slots have independent progress', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1');
    await ctrl.createSlot('slot2');

    c.read(activeSlotProvider.notifier).select('slot1');
    await c.read(progressRepositoryProvider).markCleared('scene01');

    c.read(activeSlotProvider.notifier).select('slot1');
    expect(c.read(progressRepositoryProvider).isCleared('scene01'), isTrue);
    c.read(activeSlotProvider.notifier).select('slot2');
    expect(c.read(progressRepositoryProvider).isCleared('scene01'), isFalse);
  });

  test('resetSlot clears progress and uncreates', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1');
    await ctrl.resetSlot('slot1');

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isFalse);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('progress.slot1.unlockedSceneIds'), isNull);
  });

  test('enterFreeMode unlocks all catalog scenes in free namespace', () async {
    final c = await _container();
    await c.read(saveSlotControllerProvider.notifier).enterFreeMode();

    final prefs = c.read(sharedPreferencesProvider);
    final freeRepo = ProgressRepository(prefs, kFreeModeSlotId);
    for (final entry in kSceneCatalog) {
      expect(
        freeRepo.isUnlocked(entry.id),
        isTrue,
        reason: '${entry.id} should be unlocked in free mode',
      );
    }
  });

  test('enterFreeMode does not affect real slots', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1');
    await ctrl.enterFreeMode();

    c.read(activeSlotProvider.notifier).select('slot1');
    final progress = c.read(progressRepositoryProvider);
    expect(progress.isUnlocked('scene01'), isTrue);
    expect(progress.isUnlocked('scene09'), isFalse);
  });
}
