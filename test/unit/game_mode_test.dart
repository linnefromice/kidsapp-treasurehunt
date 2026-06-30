import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

void main() {
  group('GameMode', () {
    test('has exactly four modes in difficulty order', () {
      expect(GameMode.values, [
        GameMode.easy,
        GameMode.normal,
        GameMode.hard,
        GameMode.pro,
      ]);
    });

    test('scrolls only for hard and pro (large pan/zoom area)', () {
      expect(GameMode.easy.scrolls, isFalse);
      expect(GameMode.normal.scrolls, isFalse);
      expect(GameMode.hard.scrolls, isTrue);
      expect(GameMode.pro.scrolls, isTrue);
    });

    test('blinks for every mode except easy', () {
      expect(GameMode.easy.blinks, isFalse);
      expect(GameMode.normal.blinks, isTrue);
      expect(GameMode.hard.blinks, isTrue);
      expect(GameMode.pro.blinks, isTrue);
    });

    test('hasLives only for pro (no-fail elsewhere)', () {
      expect(GameMode.easy.hasLives, isFalse);
      expect(GameMode.normal.hasLives, isFalse);
      expect(GameMode.hard.hasLives, isFalse);
      expect(GameMode.pro.hasLives, isTrue);
    });
  });

  group('gameModeFromQuery', () {
    test('"normal" maps to GameMode.normal', () {
      expect(gameModeFromQuery('normal'), GameMode.normal);
    });

    test('"hard" maps to GameMode.hard', () {
      expect(gameModeFromQuery('hard'), GameMode.hard);
    });

    test('"pro" maps to GameMode.pro', () {
      expect(gameModeFromQuery('pro'), GameMode.pro);
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
