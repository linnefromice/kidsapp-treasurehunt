import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';

void main() {
  group('TrailColorChoice.fromId', () {
    test('returns the matching choice for a known id', () {
      expect(TrailColorChoice.fromId('pink'), TrailColorChoice.pink);
      expect(TrailColorChoice.fromId('white'), TrailColorChoice.white);
    });

    test('falls back to sky for an unknown id', () {
      expect(TrailColorChoice.fromId('chartreuse'), TrailColorChoice.sky);
    });

    test('falls back to sky for null', () {
      expect(TrailColorChoice.fromId(null), TrailColorChoice.sky);
    });

    test('fallback constant is sky', () {
      expect(TrailColorChoice.fallback, TrailColorChoice.sky);
    });
  });

  group('palette', () {
    test('exposes exactly the six solid colours', () {
      expect(TrailColorChoice.values.map((c) => c.id), [
        'sky',
        'pink',
        'yellow',
        'purple',
        'orange',
        'white',
      ]);
    });

    test('every id is unique', () {
      final ids = TrailColorChoice.values.map((c) => c.id).toSet();
      expect(ids.length, TrailColorChoice.values.length);
    });
  });

  group('resolveTrailColor', () {
    test('returns the base colour regardless of particle index (solid)', () {
      for (final choice in TrailColorChoice.values) {
        expect(resolveTrailColor(choice, particleIndex: 0), choice.baseColor);
        expect(resolveTrailColor(choice, particleIndex: 999), choice.baseColor);
      }
    });

    test('sky resolves to the expected light-blue', () {
      expect(
        resolveTrailColor(TrailColorChoice.sky, particleIndex: 3),
        const Color(0xFF42A5F5),
      );
    });
  });
}
