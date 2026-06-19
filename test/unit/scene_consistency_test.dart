import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

/// 全シーンが満たすべき整合性の不変条件を検証する。
///
/// 最重要なのは「ダミーのアイコン集合 ∩ ターゲットのアイコン集合 = 空」。
/// これが破れると、探す対象と同じ見た目の偽物が画面に増え、
/// 「ハート2つ探すのに画面に3つ出る」ような混乱が起きる（ダミーはヒット判定外）。
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

  test('catalog exposes every playable scene', () {
    expect(sceneIds, isNotEmpty);
  });

  for (final sceneId in sceneIds) {
    test('$sceneId: dummy icons never collide with target icons', () async {
      final scene = await load(sceneId);

      final targetIcons = scene.targets.map((t) => t.iconId).toSet();
      final dummyIcons = scene.dummies.map((d) => d.iconId).toSet();
      final clash = targetIcons.intersection(dummyIcons);

      expect(
        clash,
        isEmpty,
        reason:
            'Dummies in $sceneId reuse target icon(s) $clash. A dummy that '
            'shares a target iconId looks like a treasure but is never '
            'hit-tested, breaking the "find N" count.',
      );
    });

    test('$sceneId: ids are unique across targets and dummies', () async {
      final scene = await load(sceneId);
      final ids = [
        ...scene.targets.map((t) => t.id),
        ...scene.dummies.map((d) => d.id),
      ];
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'Duplicate id found in $sceneId: $ids',
      );
    });

    test('$sceneId: every icon id is a known icon (no "?" fallback)', () async {
      final scene = await load(sceneId);
      final unknown = [
        ...scene.targets.map((t) => t.iconId),
        ...scene.dummies.map((d) => d.iconId),
      ].where((id) => !hasTargetIcon(id)).toSet();

      expect(
        unknown,
        isEmpty,
        reason:
            'Unknown icon id(s) $unknown in $sceneId render as a "?" '
            '(help_outline). Add them to target_icons.dart.',
      );
    });
  }
}
