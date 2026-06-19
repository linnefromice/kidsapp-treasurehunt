import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

void main() {
  group('GameMode', () {
    test('has exactly three modes in difficulty order', () {
      expect(GameMode.values, [GameMode.easy, GameMode.normal, GameMode.hard]);
    });
  });

  group('gameModeFromQuery', () {
    test('"normal" maps to GameMode.normal', () {
      expect(gameModeFromQuery('normal'), GameMode.normal);
    });

    test('"hard" maps to GameMode.hard', () {
      expect(gameModeFromQuery('hard'), GameMode.hard);
    });

    test('"easy" maps to GameMode.easy', () {
      expect(gameModeFromQuery('easy'), GameMode.easy);
    });

    test('null falls back to GameMode.easy (gentlest default)', () {
      expect(gameModeFromQuery(null), GameMode.easy);
    });

    test('unknown value falls back to GameMode.easy', () {
      expect(gameModeFromQuery('whatever'), GameMode.easy);
    });
  });
}
