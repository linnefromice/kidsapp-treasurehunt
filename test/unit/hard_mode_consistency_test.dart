import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/hard_mode.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

/// ハードモードの整合性不変条件を検証する。
///
/// ハードモードは [hardModeSceneDef] で「既存ダミー → ターゲット昇格」するため、
/// ハードのターゲット集合 = 通常ターゲット ∪ 通常ダミー になる。よって
/// 引っかけ役の [SceneDef.hardDummies] は、この合体ターゲット集合と
/// アイコンが衝突してはならない（衝突すると探す対象と同じ見た目の偽物が出る）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sceneIds = kSceneCatalog
      .where((e) => e.hasScene)
      .map((e) => e.id)
      .toList(growable: false);

  Future<SceneDef> load(String sceneId) async {
    try {
      return await SceneDef.loadAsset(sceneId);
    } on Object catch (e) {
      fail('Could not load scene asset "$sceneId": $e');
    }
  }

  for (final sceneId in sceneIds) {
    test('$sceneId: hard mode increases the number to find', () async {
      final base = await load(sceneId);
      final hard = hardModeSceneDef(base);

      // 昇格により探す量は「ターゲット + ダミー」へ増える。
      expect(
        hard.targets,
        hasLength(base.targets.length + base.dummies.length),
      );
      expect(
        hard.targets.length,
        greaterThan(base.targets.length),
        reason: '$sceneId hard mode should have more targets than normal',
      );
    });

    test('$sceneId: defines hard-only decoys', () async {
      final base = await load(sceneId);
      expect(
        base.hardDummies,
        isNotEmpty,
        reason:
            '$sceneId must define hardDummies so hard mode still has decoys',
      );
    });

    test('$sceneId: hard decoy icons never collide with hard targets', () async {
      final hard = hardModeSceneDef(await load(sceneId));
      final targetIcons = hard.targets.map((t) => t.iconId).toSet();
      final decoyIcons = hard.dummies.map((d) => d.iconId).toSet();
      final clash = targetIcons.intersection(decoyIcons);

      expect(
        clash,
        isEmpty,
        reason:
            'Hard decoys in $sceneId reuse a hard-target icon $clash. Because '
            'every normal dummy is promoted to a target in hard mode, decoys '
            'must use brand-new icons, or they look like treasures yet are '
            'never hit-tested.',
      );
    });

    test('$sceneId: ids are unique across hard targets and decoys', () async {
      final hard = hardModeSceneDef(await load(sceneId));
      final ids = [
        ...hard.targets.map((t) => t.id),
        ...hard.dummies.map((d) => d.id),
      ];
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'Duplicate id in hard $sceneId: $ids',
      );
    });

    test('$sceneId: every hard icon id is a known icon', () async {
      final hard = hardModeSceneDef(await load(sceneId));
      final unknown = [
        ...hard.targets.map((t) => t.iconId),
        ...hard.dummies.map((d) => d.iconId),
      ].where((id) => !hasTargetIcon(id)).toSet();

      expect(
        unknown,
        isEmpty,
        reason:
            'Unknown icon id(s) $unknown in hard $sceneId render as "?" '
            '(help_outline). Add them to target_icons.dart.',
      );
    });
  }
}
