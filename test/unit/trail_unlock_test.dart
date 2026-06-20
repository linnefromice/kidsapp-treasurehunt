import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

final _allSceneIds = kSceneCatalog.map((e) => e.id).toList(growable: false);

Future<void> _clearAll(ProgressRepository progress, GameMode mode) async {
  for (final id in _allSceneIds) {
    await progress.markCleared(mode, id);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('syncTrailUnlocks', () {
    test('does not unlock when a mode is only partly cleared', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      final settings = SettingsRepository(prefs);
      await progress.markCleared(GameMode.easy, _allSceneIds.first);

      await syncTrailUnlocks(progress, settings);

      expect(settings.trailStyleUnlocked('rainbow3'), isFalse);
      expect(settings.trailStyleUnlocked('rainbowFull'), isFalse);
    });

    test('unlocks rainbow3 when easy is fully cleared', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      final settings = SettingsRepository(prefs);
      await _clearAll(progress, GameMode.easy);

      await syncTrailUnlocks(progress, settings);

      expect(settings.trailStyleUnlocked('rainbow3'), isTrue);
      expect(settings.trailStyleUnlocked('rainbowFull'), isFalse);
    });

    test('unlocks rainbowFull when hard is fully cleared', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      final settings = SettingsRepository(prefs);
      await _clearAll(progress, GameMode.hard);

      await syncTrailUnlocks(progress, settings);

      expect(settings.trailStyleUnlocked('rainbowFull'), isTrue);
    });

    test('is sticky: stays unlocked even after progress is wiped', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      final settings = SettingsRepository(prefs);
      await _clearAll(progress, GameMode.easy);
      await syncTrailUnlocks(progress, settings);

      await progress.clearAll();

      // フラグは進捗とは独立に立ったまま（global sticky）。
      expect(settings.trailStyleUnlocked('rainbow3'), isTrue);
    });
  });

  group('unlockedTrailStylesProvider', () {
    ProviderContainer makeContainer(SharedPreferences prefs, String? slotId) {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      if (slotId != null) {
        container.read(activeSlotProvider.notifier).select(slotId);
      }
      return container;
    }

    test('solid is always unlocked, rainbows locked by default', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = makeContainer(prefs, null);

      final unlocked = container.read(unlockedTrailStylesProvider);
      expect(unlocked, contains(TrailStyle.solid));
      expect(unlocked, isNot(contains(TrailStyle.rainbow3)));
      expect(unlocked, isNot(contains(TrailStyle.rainbowFull)));
    });

    test('respects a persisted global unlock flag (no active slot)', () async {
      SharedPreferences.setMockInitialValues({
        'settings.trailUnlock.rainbow3': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = makeContainer(prefs, null);

      final unlocked = container.read(unlockedTrailStylesProvider);
      expect(unlocked, contains(TrailStyle.rainbow3));
      expect(unlocked, isNot(contains(TrailStyle.rainbowFull)));
    });

    test('unlocks rainbow3 from active slot live progress', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      await _clearAll(progress, GameMode.easy);
      final container = makeContainer(prefs, 'slot1');

      final unlocked = container.read(unlockedTrailStylesProvider);
      expect(unlocked, contains(TrailStyle.rainbow3));
      expect(unlocked, isNot(contains(TrailStyle.rainbowFull)));
    });

    test('live-progress unlock is persisted (sticky) as a flag', () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      await _clearAll(progress, GameMode.hard);
      final container = makeContainer(prefs, 'slot1');

      // 参照すると副作用で永続化される。
      container.read(unlockedTrailStylesProvider);
      await Future<void>.delayed(Duration.zero); // unawaited sync を流す

      expect(
        SettingsRepository(prefs).trailStyleUnlocked('rainbowFull'),
        isTrue,
      );
    });
  });
}
