import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

Future<ProgressRepository> _repo() async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs, 'slot1');
}

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

  for (final mode in GameMode.values) {
    group('completeScene (${mode.name})', () {
      test('marks cleared and unlocks the next scene', () async {
        final progress = await _repo();
        await completeScene(progress, mode, 'scene01');
        expect(progress.isCleared(mode, 'scene01'), isTrue);
        expect(progress.isUnlocked(mode, 'scene02'), isTrue);
      });

      test('unlocks the next on an extended-chain link', () async {
        final progress = await _repo();
        await completeScene(progress, mode, 'scene05');
        expect(progress.isCleared(mode, 'scene05'), isTrue);
        expect(progress.isUnlocked(mode, 'scene06'), isTrue);
      });

      test('on the last scene does not throw / unlock', () async {
        final progress = await _repo();
        await completeScene(progress, mode, 'scene09');
        expect(progress.isCleared(mode, 'scene09'), isTrue);
        expect(progress.isUnlocked(mode, 'scene09'), isFalse);
      });
    });
  }

  test('completeScene chains are independent per mode', () async {
    final progress = await _repo();
    await completeScene(progress, GameMode.normal, 'scene01');

    // Normal advanced, but easy/hard chains are untouched.
    expect(progress.isUnlocked(GameMode.normal, 'scene02'), isTrue);
    expect(progress.isCleared(GameMode.normal, 'scene01'), isTrue);
    expect(progress.isUnlocked(GameMode.easy, 'scene02'), isFalse);
    expect(progress.isCleared(GameMode.easy, 'scene01'), isFalse);
    expect(progress.isUnlocked(GameMode.hard, 'scene02'), isFalse);
    expect(progress.isCleared(GameMode.hard, 'scene01'), isFalse);
  });
}
