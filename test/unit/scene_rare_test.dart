import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';

SceneDef _scene({int dummies = 3}) => SceneDef(
  id: 'scene01',
  titleKey: 'k',
  imageAsset: 'a.png',
  targets: const [
    FindTarget(
      id: 'apple_1',
      iconId: 'apple',
      labelKey: 'target.apple',
      normalizedRect: Rect.fromLTWH(0.1, 0.1, 0.11, 0.13),
    ),
  ],
  dummies: [
    for (var i = 0; i < dummies; i++)
      DummyItem(
        id: 'd$i',
        iconId: 'leaf',
        normalizedRect: Rect.fromLTWH(0.3 + 0.05 * i, 0.5, 0.10, 0.12),
      ),
  ],
);

const _rare = RareTreasure('rare_gem', 'rare.gem');

void main() {
  test('borrows a dummy slot: +1 target, -1 dummy, rare placed there', () {
    final base = _scene(dummies: 3);
    final out = base.withRareTreasure(_rare, Random(1));

    expect(out.targets.length, base.targets.length + 1);
    expect(out.dummies.length, base.dummies.length - 1);

    final rareTarget = out.targets.firstWhere((t) => isRareIcon(t.iconId));
    expect(rareTarget.iconId, 'rare_gem');
    // レアは「借りたダミー」と同じ中心に置かれる（＝既存と非重複の升）。
    final dummyCenters = base.dummies
        .map((d) => d.normalizedRect.center)
        .toSet();
    expect(dummyCenters.contains(rareTarget.normalizedRect.center), isTrue);
    // 借りたダミーは取り除かれている（中心がもう残っていない）。
    final remaining = out.dummies.map((d) => d.normalizedRect.center).toSet();
    expect(remaining.contains(rareTarget.normalizedRect.center), isFalse);
  });

  test('keeps base targets and the other dummies intact', () {
    final base = _scene(dummies: 3);
    final out = base.withRareTreasure(_rare, Random(2));
    expect(out.targets.any((t) => t.id == 'apple_1'), isTrue);
    expect(out.dummies.length, 2);
  });

  test('no dummies => no rare injected (returns equivalent scene)', () {
    final base = _scene(dummies: 0);
    final out = base.withRareTreasure(_rare, Random(3));
    expect(out.targets.any((t) => isRareIcon(t.iconId)), isFalse);
    expect(out.targets.length, base.targets.length);
  });
}
