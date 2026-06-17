import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

Future<ProgressRepository> _repo(String slotId) async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs, slotId);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ensureInitialUnlock unlocks first scene only when empty', () async {
    final r = await _repo('slot1');
    await r.ensureInitialUnlock('scene01');
    expect(r.isUnlocked('scene01'), isTrue);
    expect(r.isUnlocked('scene02'), isFalse);
  });

  test('markCleared records scene as cleared', () async {
    final r = await _repo('slot1');
    expect(r.isCleared('scene01'), isFalse);
    await r.markCleared('scene01');
    expect(r.isCleared('scene01'), isTrue);
  });

  test('slots are independent', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = ProgressRepository(prefs, 'slot1');
    final s2 = ProgressRepository(prefs, 'slot2');
    await s1.markCleared('scene01');
    expect(s1.isCleared('scene01'), isTrue);
    expect(s2.isCleared('scene01'), isFalse);
  });

  test('clearAll empties the slot', () async {
    final r = await _repo('slot1');
    await r.ensureInitialUnlock('scene01');
    await r.markCleared('scene01');
    await r.clearAll();
    expect(r.unlockedSceneIds(), isEmpty);
    expect(r.clearedSceneIds(), isEmpty);
  });
}
