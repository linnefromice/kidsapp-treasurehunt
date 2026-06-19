import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

Future<ProgressRepository> _repo(String slotId) async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs, slotId);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ensureInitialUnlock unlocks first scene only when empty', () async {
    final r = await _repo('slot1');
    await r.ensureInitialUnlock(GameMode.easy, 'scene01');
    expect(r.isUnlocked(GameMode.easy, 'scene01'), isTrue);
    expect(r.isUnlocked(GameMode.easy, 'scene02'), isFalse);
  });

  test('markCleared records scene as cleared', () async {
    final r = await _repo('slot1');
    expect(r.isCleared(GameMode.easy, 'scene01'), isFalse);
    await r.markCleared(GameMode.easy, 'scene01');
    expect(r.isCleared(GameMode.easy, 'scene01'), isTrue);
  });

  test('slots are independent', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = ProgressRepository(prefs, 'slot1');
    final s2 = ProgressRepository(prefs, 'slot2');
    await s1.markCleared(GameMode.easy, 'scene01');
    expect(s1.isCleared(GameMode.easy, 'scene01'), isTrue);
    expect(s2.isCleared(GameMode.easy, 'scene01'), isFalse);
  });

  test('clearAll empties every mode in the slot', () async {
    final r = await _repo('slot1');
    for (final mode in GameMode.values) {
      await r.ensureInitialUnlock(mode, 'scene01');
      await r.markCleared(mode, 'scene01');
    }
    await r.clearAll();
    for (final mode in GameMode.values) {
      expect(r.unlockedSceneIds(mode), isEmpty, reason: '$mode unlocked');
      expect(r.clearedSceneIds(mode), isEmpty, reason: '$mode cleared');
    }
  });

  group('per-mode independence', () {
    test('clearing in one mode does not leak into the others', () async {
      final r = await _repo('slot1');
      await r.markCleared(GameMode.normal, 'scene01');

      expect(r.isCleared(GameMode.normal, 'scene01'), isTrue);
      expect(r.isCleared(GameMode.easy, 'scene01'), isFalse);
      expect(r.isCleared(GameMode.hard, 'scene01'), isFalse);
    });

    test('unlocking in one mode does not leak into the others', () async {
      final r = await _repo('slot1');
      await r.unlock(GameMode.hard, 'scene02');

      expect(r.isUnlocked(GameMode.hard, 'scene02'), isTrue);
      expect(r.isUnlocked(GameMode.easy, 'scene02'), isFalse);
      expect(r.isUnlocked(GameMode.normal, 'scene02'), isFalse);
    });

    test('each mode keeps its own initial unlock', () async {
      final r = await _repo('slot1');
      await r.ensureInitialUnlock(GameMode.easy, 'scene01');
      // normal/hard untouched → still empty.
      expect(r.unlockedSceneIds(GameMode.easy), ['scene01']);
      expect(r.unlockedSceneIds(GameMode.normal), isEmpty);
      expect(r.unlockedSceneIds(GameMode.hard), isEmpty);
    });
  });

  group('legacy key compatibility (Easy reuses pre-3-mode keys)', () {
    test(
      'Easy reads existing unlock/cleared lists written before modes',
      () async {
        SharedPreferences.setMockInitialValues({
          'progress.slot1.unlockedSceneIds': ['scene01', 'scene02'],
          'progress.slot1.clearedSceneIds': ['scene01'],
        });
        final r = await _repo('slot1');
        expect(r.isUnlocked(GameMode.easy, 'scene02'), isTrue);
        expect(r.isCleared(GameMode.easy, 'scene01'), isTrue);
        // Those legacy keys must NOT bleed into the new modes.
        expect(r.unlockedSceneIds(GameMode.normal), isEmpty);
        expect(r.unlockedSceneIds(GameMode.hard), isEmpty);
      },
    );

    test('Hard cleared reuses the legacy hardClearedSceneIds key', () async {
      SharedPreferences.setMockInitialValues({
        'progress.slot1.hardClearedSceneIds': ['scene01'],
      });
      final r = await _repo('slot1');
      expect(r.isCleared(GameMode.hard, 'scene01'), isTrue);
      expect(r.isCleared(GameMode.easy, 'scene01'), isFalse);
    });
  });

  group('unlockAll', () {
    test('unlocks every passed scene for the mode', () async {
      final r = await _repo('free');
      await r.unlockAll(GameMode.easy, ['scene01', 'scene02', 'scene03']);
      expect(r.isUnlocked(GameMode.easy, 'scene01'), isTrue);
      expect(r.isUnlocked(GameMode.easy, 'scene02'), isTrue);
      expect(r.isUnlocked(GameMode.easy, 'scene03'), isTrue);
    });

    test('is idempotent', () async {
      final r = await _repo('free');
      await r.unlockAll(GameMode.easy, ['scene01', 'scene02']);
      await r.unlockAll(GameMode.easy, ['scene01', 'scene02']);
      expect(r.unlockedSceneIds(GameMode.easy)..sort(), ['scene01', 'scene02']);
    });

    test('merges with already unlocked scenes', () async {
      final r = await _repo('free');
      await r.unlock(GameMode.easy, 'scene01');
      await r.unlockAll(GameMode.easy, ['scene02', 'scene03']);
      expect(r.unlockedSceneIds(GameMode.easy)..sort(), [
        'scene01',
        'scene02',
        'scene03',
      ]);
    });
  });
}
