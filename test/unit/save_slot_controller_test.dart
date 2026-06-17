import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

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
}
