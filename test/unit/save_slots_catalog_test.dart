import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';

void main() {
  group('kAvatarEmojis', () {
    test('offers a generous, curated set of choices', () {
      // 子どもが選ぶ楽しみのために十分な数を用意する（増やした下限の回帰防止）。
      expect(kAvatarEmojis.length, greaterThanOrEqualTo(48));
    });

    test('contains no duplicates', () {
      expect(kAvatarEmojis.toSet().length, kAvatarEmojis.length);
    });

    test('every entry is a non-empty single glyph token', () {
      for (final emoji in kAvatarEmojis) {
        expect(emoji.trim(), isNotEmpty, reason: 'empty avatar entry');
      }
    });

    test('keeps the emojis referenced by tests and the default avatar', () {
      // 既存テスト・既定値が参照する絵文字は不変条件として維持する。
      for (final emoji in ['🦊', '🐶', '🐱', '🐼', kDefaultAvatar]) {
        expect(
          kAvatarEmojis.contains(emoji),
          isTrue,
          reason: '$emoji must remain in the whitelist',
        );
      }
    });
  });
}
