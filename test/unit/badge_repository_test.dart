import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/data/badge_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BadgeRepository> repo(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    return BadgeRepository(prefs, slot);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('grant returns only newly earned and persists them', () async {
    final r = await repo('A');
    final first = await r.grant({'firstFind', 'firstClear'});
    expect(first, {'firstFind', 'firstClear'});
    expect(r.earned(), {'firstFind', 'firstClear'});

    // 再評価で同じ＋新規 → 新規分だけ返る（冪等）。
    final second = await r.grant({'firstFind', 'firstClear', 'explorer'});
    expect(second, {'explorer'});
    expect(r.earned(), {'firstFind', 'firstClear', 'explorer'});

    // 増分なしなら空。
    expect(await r.grant({'firstFind'}), isEmpty);
  });

  test('newly earned go to unseen and markSeen clears them', () async {
    final r = await repo('A');
    await r.grant({'firstFind', 'rareFirst'});
    expect(r.unseen(), {'firstFind', 'rareFirst'});
    await r.markSeen({'firstFind'});
    expect(r.unseen(), {'rareFirst'});
    await r.markSeen({'rareFirst'});
    expect(r.unseen(), isEmpty);
  });

  test('badges are namespaced per slot (independent)', () async {
    final a = await repo('A');
    final b = await repo('B');
    await a.grant({'firstClear'});
    expect(a.isEarned('firstClear'), isTrue);
    expect(b.isEarned('firstClear'), isFalse);
    expect(b.earned(), isEmpty);
  });
}
