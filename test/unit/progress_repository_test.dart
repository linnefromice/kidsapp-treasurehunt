import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

Future<ProgressRepository> _repo() async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ensureInitialUnlock unlocks first scene only when empty', () async {
    final repo = await _repo();
    await repo.ensureInitialUnlock('scene01');
    expect(repo.isUnlocked('scene01'), isTrue);
    expect(repo.isUnlocked('scene02'), isFalse);
  });

  test('ensureInitialUnlock does not overwrite existing unlocks', () async {
    SharedPreferences.setMockInitialValues({
      'progress.unlockedSceneIds': ['scene02'],
    });
    final repo = await _repo();
    await repo.ensureInitialUnlock('scene01');
    expect(repo.isUnlocked('scene02'), isTrue);
    expect(repo.isUnlocked('scene01'), isFalse);
  });

  test('markCleared records scene as cleared', () async {
    final repo = await _repo();
    expect(repo.isCleared('scene01'), isFalse);
    await repo.markCleared('scene01');
    expect(repo.isCleared('scene01'), isTrue);
  });
}
