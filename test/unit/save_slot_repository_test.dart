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
}
