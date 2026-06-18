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
    expect(nextSceneId('scene05'), isNull);
    expect(nextSceneId('mystery'), isNull);
  });

  test('completeScene marks cleared and unlocks the next scene', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene01');
    expect(progress.isCleared('scene01'), isTrue);
    expect(progress.isUnlocked('scene02'), isTrue);
  });

  test('completeScene on the last scene does not throw / unlock', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene05');
    expect(progress.isCleared('scene05'), isTrue);
    expect(progress.isUnlocked('scene05'), isFalse);
  });
}
