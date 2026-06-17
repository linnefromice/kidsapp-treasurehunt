import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

void main() {
  test('resolves localized string', () {
    expect(tr('ja', 'home.title'), 'たからの ちず');
    expect(tr('en', 'home.title'), 'Treasure Map');
  });

  test('falls back to ja then key for unknown', () {
    expect(tr('en', 'definitely.missing'), 'definitely.missing');
  });

  test('resolves slot strings', () {
    expect(tr('ja', 'slot.title'), 'だれが あそぶ?');
    expect(tr('en', 'slot.title'), 'Who is playing?');
    expect(tr('ja', 'slot.new'), 'あたらしく');
    expect(tr('ja', 'slot.continue'), 'つづき');
  });
}
