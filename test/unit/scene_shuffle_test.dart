import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

bool _overlaps(Rect a, Rect b) =>
    a.left < b.right &&
    b.left < a.right &&
    a.top < b.bottom &&
    b.top < a.bottom;

SceneDef _scene() => SceneDef(
  id: 'scene01',
  titleKey: 'scene.scene01.title',
  imageAsset: 'assets/scenes/scene01.png',
  targets: [
    for (var i = 0; i < 6; i++)
      FindTarget(
        id: 't$i',
        iconId: i.isEven ? 'apple' : 'star',
        labelKey: 'target.apple',
        normalizedRect: Rect.fromLTWH(0.1 * i, 0.05 * i, 0.11, 0.13),
      ),
  ],
  dummies: [
    for (var i = 0; i < 5; i++)
      DummyItem(
        id: 'd$i',
        iconId: 'leaf',
        normalizedRect: Rect.fromLTWH(0.05 * i, 0.5 + 0.05 * i, 0.10, 0.12),
      ),
  ],
  hardDummies: [
    for (var i = 0; i < 4; i++)
      DummyItem(
        id: 'h$i',
        iconId: 'gem',
        normalizedRect: Rect.fromLTWH(0.6 + 0.05 * i, 0.1 * i, 0.10, 0.12),
        scale: 0.8,
      ),
  ],
);

Set<Offset> _centers(SceneDef s) => {
  ...s.targets.map((t) => t.normalizedRect.center),
  ...s.dummies.map((d) => d.normalizedRect.center),
  ...s.hardDummies.map((d) => d.normalizedRect.center),
};

void main() {
  test('preserves identity: id/titleKey/imageAsset and counts', () {
    final base = _scene();
    final shuffled = base.withShuffledPositions(Random(1));
    expect(shuffled.id, base.id);
    expect(shuffled.titleKey, base.titleKey);
    expect(shuffled.imageAsset, base.imageAsset);
    expect(shuffled.targets, hasLength(base.targets.length));
    expect(shuffled.dummies, hasLength(base.dummies.length));
    expect(shuffled.hardDummies, hasLength(base.hardDummies.length));
  });

  test('keeps every id, icon and scale (only positions move)', () {
    final base = _scene();
    final shuffled = base.withShuffledPositions(Random(2));
    expect(
      shuffled.targets.map((t) => t.id).toSet(),
      base.targets.map((t) => t.id).toSet(),
    );
    expect(
      shuffled.targets.map((t) => t.iconId).toList(),
      base.targets.map((t) => t.iconId).toList(),
    );
    expect(
      {
        ...shuffled.dummies,
        ...shuffled.hardDummies,
      }.map((d) => d.iconId).toSet(),
      {...base.dummies, ...base.hardDummies}.map((d) => d.iconId).toSet(),
    );
    for (final h in shuffled.hardDummies) {
      expect(h.scale, 0.8); // scale は各アイテムが保持
    }
  });

  test('each item keeps its own size (width/height) after relocation', () {
    final base = _scene();
    final shuffled = base.withShuffledPositions(Random(3));
    for (final t in shuffled.targets) {
      expect(t.normalizedRect.width, closeTo(0.11, 1e-9));
      expect(t.normalizedRect.height, closeTo(0.13, 1e-9));
    }
    for (final d in shuffled.dummies) {
      expect(d.normalizedRect.width, closeTo(0.10, 1e-9));
      expect(d.normalizedRect.height, closeTo(0.12, 1e-9));
    }
  });

  test(
    'the set of centers is preserved (positions are permuted, not invented)',
    () {
      final base = _scene();
      final shuffled = base.withShuffledPositions(Random(4));
      expect(_centers(shuffled), _centers(base));
    },
  );

  test('is deterministic for a given seed', () {
    final base = _scene();
    final a = base.withShuffledPositions(Random(7));
    final b = base.withShuffledPositions(Random(7));
    expect(
      a.targets.map((t) => t.normalizedRect.center).toList(),
      b.targets.map((t) => t.normalizedRect.center).toList(),
    );
  });

  group('real scenes stay non-overlapping after shuffle', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    final sceneIds = kSceneCatalog
        .where((e) => e.hasScene)
        .map((e) => e.id)
        .toList(growable: false);

    void expectNoOverlap(List<Rect> rects, String reason) {
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            _overlaps(rects[i], rects[j]),
            isFalse,
            reason: '$reason: rect $i overlaps rect $j',
          );
        }
      }
    }

    for (final id in sceneIds) {
      test(
        '$id: easy & hard item sets remain non-overlapping (seeds 0–3)',
        () async {
          final base = await SceneDef.loadAsset(id);
          for (var seed = 0; seed < 4; seed++) {
            final s = base.withShuffledPositions(Random(seed));
            // Easy で描画する集合（宝 + 通常おとり）。
            final easy = [
              ...decoysForMode(s, GameMode.easy).map((d) => d.normalizedRect),
              ...s.targets.map((t) => t.normalizedRect),
            ];
            expectNoOverlap(easy, '$id/easy seed=$seed');
            // Hard で描画する集合（宝 + 通常おとり + ハードおとり）。
            final hard = [
              ...decoysForMode(s, GameMode.hard).map((d) => d.normalizedRect),
              ...s.targets.map((t) => t.normalizedRect),
            ];
            expectNoOverlap(hard, '$id/hard seed=$seed');
          }
        },
      );
    }
  });

  test('actually relocates at least one item (some seed permutes)', () {
    final base = _scene();
    // 複数シードのどれかで必ず位置が動く（恒等置換だけということはない）。
    final moved =
        [for (var s = 0; s < 5; s++) base.withShuffledPositions(Random(s))].any(
          (sh) {
            for (var i = 0; i < base.targets.length; i++) {
              if (sh.targets[i].normalizedRect.center !=
                  base.targets[i].normalizedRect.center) {
                return true;
              }
            }
            return false;
          },
        );
    expect(moved, isTrue);
  });
}
