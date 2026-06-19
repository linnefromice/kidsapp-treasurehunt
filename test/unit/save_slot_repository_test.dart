import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('markCreated / removeCreated track slot ids', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SaveSlotRepository(prefs);

    expect(repo.isCreated('slot1'), isFalse);
    await repo.markCreated('slot1');
    expect(repo.isCreated('slot1'), isTrue);
    expect(repo.createdSlotIds(), ['slot1']);

    await repo.removeCreated('slot1');
    expect(repo.isCreated('slot1'), isFalse);
  });

  test('avatar is stored, read back, and removable per slot', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SaveSlotRepository(prefs);

    expect(repo.avatarOf('slot1'), isNull);

    await repo.setAvatar('slot1', '🦊');
    await repo.setAvatar('slot2', '🐼');
    expect(repo.avatarOf('slot1'), '🦊');
    expect(repo.avatarOf('slot2'), '🐼');

    await repo.removeAvatar('slot1');
    expect(repo.avatarOf('slot1'), isNull);
    // 他スロットのアバターには影響しない。
    expect(repo.avatarOf('slot2'), '🐼');
  });
}
