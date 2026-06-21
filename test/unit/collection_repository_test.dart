import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/collection_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CollectionRepository> repo(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    return CollectionRepository(prefs, slot);
  }

  test('starts empty and nothing is discovered', () async {
    final r = await repo('slot1');
    expect(r.discovered(), isEmpty);
    expect(r.isDiscovered('scene01', 'apple'), isFalse);
  });

  test('records a discovery and reports it as discovered', () async {
    final r = await repo('slot1');
    final isNew = await r.record('scene01', 'apple');
    expect(isNew, isTrue);
    expect(r.isDiscovered('scene01', 'apple'), isTrue);
    expect(r.discovered(), {'scene01:apple'});
  });

  test(
    'recording the same treasure again is a no-op (returns false)',
    () async {
      final r = await repo('slot1');
      expect(await r.record('scene01', 'apple'), isTrue);
      expect(await r.record('scene01', 'apple'), isFalse);
      expect(r.discovered(), {'scene01:apple'});
    },
  );

  test('same icon in different worlds are distinct entries', () async {
    final r = await repo('slot1');
    await r.record('scene01', 'apple');
    await r.record('scene02', 'apple');
    expect(r.isDiscovered('scene01', 'apple'), isTrue);
    expect(r.isDiscovered('scene02', 'apple'), isTrue);
    expect(r.isDiscovered('scene03', 'apple'), isFalse);
    expect(r.discovered(), {'scene01:apple', 'scene02:apple'});
  });

  test('collections are independent per slot', () async {
    final r1 = await repo('slot1');
    final r2 = await repo('slot2');
    await r1.record('scene01', 'apple');
    expect(r1.isDiscovered('scene01', 'apple'), isTrue);
    expect(r2.isDiscovered('scene01', 'apple'), isFalse);
    expect(r2.discovered(), isEmpty);
  });

  group('unseen (new! バッジ)', () {
    test('a first discovery becomes unseen', () async {
      final r = await repo('slot1');
      await r.record('scene01', 'apple');
      expect(r.isUnseen('scene01', 'apple'), isTrue);
      expect(r.unseen(), {'scene01:apple'});
    });

    test(
      're-discovering an already-found treasure does not re-flag unseen',
      () async {
        final r = await repo('slot1');
        await r.record('scene01', 'apple');
        await r.markSeen({'scene01:apple'});
        // 既収集を再度通っても new! には戻らない。
        expect(await r.record('scene01', 'apple'), isFalse);
        expect(r.isUnseen('scene01', 'apple'), isFalse);
        expect(r.unseen(), isEmpty);
      },
    );

    test('markSeen clears only the given entries, keeps discovered', () async {
      final r = await repo('slot1');
      await r.record('scene01', 'apple');
      await r.record('scene02', 'duck');
      await r.markSeen({'scene01:apple'});
      // 表示した分だけ既読。見ていない初発見は new! のまま残る。
      expect(r.isUnseen('scene01', 'apple'), isFalse);
      expect(r.isUnseen('scene02', 'duck'), isTrue);
      // 収集自体は両方とも残る。
      expect(r.isDiscovered('scene01', 'apple'), isTrue);
      expect(r.isDiscovered('scene02', 'duck'), isTrue);
    });
  });
}
