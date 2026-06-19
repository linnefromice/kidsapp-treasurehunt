import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nextSceneId follows catalog order; null at end/unknown', () {
    expect(nextSceneId('scene01'), 'scene02');
    expect(nextSceneId('scene02'), 'scene03');
    expect(nextSceneId('scene03'), 'scene04');
    expect(nextSceneId('scene04'), 'scene05');
    expect(nextSceneId('scene05'), 'scene06');
    expect(nextSceneId('scene06'), 'scene07');
    expect(nextSceneId('scene07'), 'scene08');
    expect(nextSceneId('scene08'), 'scene09');
    expect(nextSceneId('scene09'), isNull);
    expect(nextSceneId('mystery'), isNull);
  });

  test('completeScene marks cleared and unlocks the next scene', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene01');
    expect(progress.isCleared('scene01'), isTrue);
    expect(progress.isUnlocked('scene02'), isTrue);
  });

  test('completeScene unlocks the next on an extended-chain link', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene05');
    expect(progress.isCleared('scene05'), isTrue);
    expect(progress.isUnlocked('scene06'), isTrue);
  });

  test('completeScene on the last scene does not throw / unlock', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene09');
    expect(progress.isCleared('scene09'), isTrue);
    expect(progress.isUnlocked('scene09'), isFalse);
  });

  test('allScenesCleared is false until every scene is cleared', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    expect(allScenesCleared(progress), isFalse);

    for (final entry in kSceneCatalog) {
      await progress.markCleared(entry.id);
    }
    expect(allScenesCleared(progress), isTrue);
  });

  test('allScenesCleared is false when one scene is missing', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    // Clear all but the last.
    for (final entry in kSceneCatalog.take(kSceneCatalog.length - 1)) {
      await progress.markCleared(entry.id);
    }
    expect(allScenesCleared(progress), isFalse);
  });

  test(
    'completeHardScene records hard clear without touching unlocks',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final progress = ProgressRepository(prefs, 'slot1');
      await completeHardScene(progress, 'scene01');
      expect(progress.isHardCleared('scene01'), isTrue);
      // Hard completion never advances the normal unlock chain.
      expect(progress.isUnlocked('scene02'), isFalse);
      expect(progress.isCleared('scene01'), isFalse);
    },
  );
}
