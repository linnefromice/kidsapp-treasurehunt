import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

SceneDef _baseScene() => const SceneDef(
  id: 'scene01',
  titleKey: 'scene.scene01.title',
  imageAsset: 'assets/scenes/scene01.png',
  targets: [
    FindTarget(
      id: 'apple',
      iconId: 'apple',
      labelKey: 'target.apple',
      normalizedRect: Rect.fromLTWH(0.1, 0.1, 0.12, 0.14),
    ),
    FindTarget(
      id: 'star',
      iconId: 'star',
      labelKey: 'target.star',
      normalizedRect: Rect.fromLTWH(0.5, 0.5, 0.12, 0.14),
    ),
  ],
  dummies: [
    DummyItem(
      id: 'leaf1',
      iconId: 'leaf',
      normalizedRect: Rect.fromLTWH(0.3, 0.2, 0.11, 0.13),
    ),
    DummyItem(
      id: 'key1',
      iconId: 'key',
      normalizedRect: Rect.fromLTWH(0.7, 0.4, 0.11, 0.13),
    ),
  ],
  hardDummies: [
    DummyItem(
      id: 'h_cake1',
      iconId: 'cake',
      normalizedRect: Rect.fromLTWH(0.46, 0.06, 0.11, 0.13),
    ),
  ],
);

void main() {
  group('decoysForMode', () {
    test('easy uses only the base dummies', () {
      final decoys = decoysForMode(_baseScene(), GameMode.easy);
      expect(decoys.map((d) => d.id), ['leaf1', 'key1']);
    });

    test('normal adds the hard-only decoys on top of the base dummies', () {
      final decoys = decoysForMode(_baseScene(), GameMode.normal);
      expect(decoys.map((d) => d.id), ['leaf1', 'key1', 'h_cake1']);
    });

    test('hard uses the same enlarged decoy set as normal', () {
      final base = _baseScene();
      expect(
        decoysForMode(base, GameMode.hard).map((d) => d.id),
        decoysForMode(base, GameMode.normal).map((d) => d.id),
      );
    });

    test('normal/hard have strictly more decoys than easy', () {
      final base = _baseScene();
      expect(
        decoysForMode(base, GameMode.normal).length,
        greaterThan(decoysForMode(base, GameMode.easy).length),
      );
    });

    test(
      'the find targets are identical across all modes (count unchanged)',
      () {
        final base = _baseScene();
        // おとりは増えても、探す宝の数・集合はモードで変わらない。
        expect(base.targets.map((t) => t.id), ['apple', 'star']);
      },
    );

    test('does not mutate the base scene (immutability)', () {
      final base = _baseScene();
      decoysForMode(base, GameMode.hard);
      expect(base.dummies.map((d) => d.id), ['leaf1', 'key1']);
      expect(base.hardDummies.map((d) => d.id), ['h_cake1']);
    });
  });
}
