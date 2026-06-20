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

  group('TrailStyle.fromId', () {
    test('returns the matching style for a known id', () {
      expect(TrailStyle.fromId('rainbow3'), TrailStyle.rainbow3);
      expect(TrailStyle.fromId('rainbowFull'), TrailStyle.rainbowFull);
    });

    test('falls back to solid for unknown id and null', () {
      expect(TrailStyle.fromId('plaid'), TrailStyle.solid);
      expect(TrailStyle.fromId(null), TrailStyle.solid);
      expect(TrailStyle.fallback, TrailStyle.solid);
    });
  });

  group('TrailSetting.fromPersisted', () {
    test('reconstructs style, solid colour, and three colours', () {
      final setting = TrailSetting.fromPersisted(
        styleId: 'rainbow3',
        solidId: 'pink',
        colors3Csv: 'sky,purple,orange',
      );
      expect(setting.style, TrailStyle.rainbow3);
      expect(setting.solidColor, TrailColorChoice.pink);
      expect(setting.threeColors, [
        TrailColorChoice.sky,
        TrailColorChoice.purple,
        TrailColorChoice.orange,
      ]);
    });

    test('pads a short csv with the default colours', () {
      final setting = TrailSetting.fromPersisted(colors3Csv: 'pink');
      expect(setting.threeColors, [
        TrailColorChoice.pink,
        TrailColorChoice.pink, // default[1]
        TrailColorChoice.yellow, // default[2]
      ]);
    });

    test('always yields exactly three colours, even for null/empty csv', () {
      expect(TrailSetting.fromPersisted().threeColors.length, 3);
      expect(
        TrailSetting.fromPersisted(colors3Csv: '').threeColors,
        TrailSetting.defaultThreeColors,
      );
    });

    test('maps unknown ids to the fallback colour', () {
      final setting = TrailSetting.fromPersisted(colors3Csv: 'sky,nope,pink');
      expect(setting.threeColors[1], TrailColorChoice.sky); // fallback
    });

    test('allows duplicate colours in the three slots', () {
      final setting = TrailSetting.fromPersisted(colors3Csv: 'sky,sky,pink');
      expect(setting.threeColors, [
        TrailColorChoice.sky,
        TrailColorChoice.sky,
        TrailColorChoice.pink,
      ]);
    });
  });

  group('TrailSetting.withThreeColorAt / threeColorsCsv', () {
    test('replaces only the targeted slot immutably', () {
      const base = TrailSetting.fallback;
      final next = base.withThreeColorAt(1, TrailColorChoice.orange);
      expect(next.threeColors[1], TrailColorChoice.orange);
      // 元は不変。
      expect(base.threeColors[1], TrailColorChoice.pink);
    });

    test('serialises three colours back to csv', () {
      expect(TrailSetting.fallback.threeColorsCsv, 'sky,pink,yellow');
    });
  });

  group('resolveTrailColor', () {
    TrailSetting solid(TrailColorChoice c) =>
        TrailSetting.fallback.copyWith(style: TrailStyle.solid, solidColor: c);

    test('solid returns the base colour regardless of particle index', () {
      for (final choice in TrailColorChoice.values) {
        final setting = solid(choice);
        expect(resolveTrailColor(setting, particleIndex: 0), choice.baseColor);
        expect(
          resolveTrailColor(setting, particleIndex: 999),
          choice.baseColor,
        );
      }
    });

    test('rainbow3 cycles through the three colours by index % 3', () {
      final setting = TrailSetting.fromPersisted(
        styleId: 'rainbow3',
        colors3Csv: 'sky,pink,yellow',
      );
      expect(
        resolveTrailColor(setting, particleIndex: 0),
        const Color(0xFF42A5F5),
      );
      expect(
        resolveTrailColor(setting, particleIndex: 1),
        const Color(0xFFFF6FA5),
      );
      expect(
        resolveTrailColor(setting, particleIndex: 2),
        const Color(0xFFFFD54F),
      );
      // 3 周目で先頭へ戻る。
      expect(
        resolveTrailColor(setting, particleIndex: 3),
        const Color(0xFF42A5F5),
      );
    });

    test('rainbowFull varies with index and is deterministic', () {
      const setting = TrailSetting(
        style: TrailStyle.rainbowFull,
        solidColor: TrailColorChoice.sky,
        threeColors: TrailSetting.defaultThreeColors,
      );
      final c0 = resolveTrailColor(setting, particleIndex: 0);
      final c1 = resolveTrailColor(setting, particleIndex: 1);
      // 隣り合う粒は別の色相になる。
      expect(c0, isNot(c1));
      // 同じ index は常に同じ色（決定的）。
      expect(
        resolveTrailColor(setting, particleIndex: 7),
        resolveTrailColor(setting, particleIndex: 7),
      );
    });
  });
}
