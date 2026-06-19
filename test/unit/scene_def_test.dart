import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SceneDef.fromJson parses targets into normalized rects', () {
    final scene = SceneDef.fromJson(const {
      'id': 'scene01',
      'titleKey': 'scene.scene01.title',
      'imageAsset': 'assets/scenes/scene01.png',
      'targets': [
        {
          'id': 'apple',
          'labelKey': 'target.apple',
          'left': 0.1,
          'top': 0.2,
          'width': 0.3,
          'height': 0.4,
        },
      ],
    });

    expect(scene.id, 'scene01');
    expect(scene.targets, hasLength(1));
    final FindTarget t = scene.targets.single;
    expect(t.id, 'apple');
    expect(t.normalizedRect, const Rect.fromLTWH(0.1, 0.2, 0.3, 0.4));
  });

  test(
    'loads scene02 (4 targets) and scene03 (5 targets) from assets',
    () async {
      final s2 = await SceneDef.loadAsset('scene02');
      expect(s2.targets, hasLength(4));
      final s3 = await SceneDef.loadAsset('scene03');
      expect(s3.targets, hasLength(5));
    },
  );

  group('SceneDef dummy parsing', () {
    test('parses dummies from json', () {
      final def = SceneDef.fromJson({
        'id': 'test',
        'titleKey': 'k',
        'imageAsset': 'a.png',
        'targets': [],
        'dummies': [
          {
            'id': 'd1',
            'iconId': 'leaf',
            'left': 0.1,
            'top': 0.2,
            'width': 0.15,
            'height': 0.18,
          },
        ],
      });
      expect(def.dummies.length, 1);
      expect(def.dummies.first.iconId, 'leaf');
      expect(def.dummies.first.normalizedRect.left, closeTo(0.1, 0.001));
    });

    test('defaults to empty dummies when key absent', () {
      final def = SceneDef.fromJson({
        'id': 'test',
        'titleKey': 'k',
        'imageAsset': 'a.png',
        'targets': [],
      });
      expect(def.dummies, isEmpty);
    });

    test('dummy scale defaults to 1.0 when absent', () {
      final def = SceneDef.fromJson({
        'id': 'test',
        'titleKey': 'k',
        'imageAsset': 'a.png',
        'targets': [],
        'dummies': [
          {
            'id': 'd1',
            'iconId': 'leaf',
            'left': 0.1,
            'top': 0.2,
            'width': 0.15,
            'height': 0.18,
          },
        ],
      });
      expect(def.dummies.first.scale, 1.0);
    });

    test('dummy scale rejects non-positive / non-finite values', () {
      DummyItem make(double s) => DummyItem(
        id: 'd',
        iconId: 'leaf',
        normalizedRect: Rect.zero,
        scale: s,
      );
      expect(() => make(0), throwsA(isA<AssertionError>()));
      expect(() => make(-1), throwsA(isA<AssertionError>()));
      expect(() => make(double.infinity), throwsA(isA<AssertionError>()));
      expect(() => make(double.nan), throwsA(isA<AssertionError>()));
    });

    test('dummy scale is parsed when present', () {
      final def = SceneDef.fromJson({
        'id': 'test',
        'titleKey': 'k',
        'imageAsset': 'a.png',
        'targets': [],
        'dummies': [
          {
            'id': 'd1',
            'iconId': 'leaf',
            'left': 0.1,
            'top': 0.2,
            'width': 0.15,
            'height': 0.18,
            'scale': 0.6,
          },
        ],
      });
      expect(def.dummies.first.scale, closeTo(0.6, 1e-9));
    });

    test('scene01 loads with 6 dummies', () async {
      final def = await SceneDef.loadAsset('scene01');
      expect(def.dummies.length, 6);
      // `key` (not `heart`) — a dummy must never reuse a target iconId, or it
      // looks like a treasure yet is never hit-tested. See
      // scene_consistency_test.dart for the cross-scene invariant.
      expect(def.dummies.map((d) => d.iconId).toSet(), {
        'leaf',
        'rabbit',
        'bug',
        'flower',
        'key',
        'ball',
      });
    });
  });
}
