import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

/// シーンデータの整合性不変条件を検証する（おとり昇格は廃止済み）。
///
/// 探す宝（[SceneDef.targets]）はモード間で不変。Normal / Hard は
/// [SceneDef.dummies] ＋ [SceneDef.hardDummies] をおとりとして増量する。
/// したがっておとりのアイコンは宝のアイコンと衝突してはならない
/// （衝突すると探す対象と同じ見た目の偽物が出てしまう）。
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
    test('$sceneId: defines hard-only decoys to enlarge normal/hard', () async {
      final base = await load(sceneId);
      expect(
        base.hardDummies,
        isNotEmpty,
        reason:
            '$sceneId must define hardDummies so normal/hard have more decoys '
            'than easy',
      );
    });

    test('$sceneId: normal/hard have more decoys than easy', () async {
      final base = await load(sceneId);
      expect(
        decoysForMode(base, GameMode.normal).length,
        greaterThan(decoysForMode(base, GameMode.easy).length),
        reason: '$sceneId normal mode should add decoys on top of easy',
      );
    });

    for (final mode in GameMode.values) {
      test(
        '$sceneId/$mode: decoy icons never collide with target icons',
        () async {
          final base = await load(sceneId);
          final targetIcons = base.targets.map((t) => t.iconId).toSet();
          final decoyIcons = decoysForMode(
            base,
            mode,
          ).map((d) => d.iconId).toSet();
          final clash = targetIcons.intersection(decoyIcons);

          expect(
            clash,
            isEmpty,
            reason:
                'Decoys in $sceneId/$mode reuse a target icon $clash. A decoy '
                'must use a brand-new icon, or it looks like a treasure yet is '
                'never hit-tested.',
          );
        },
      );

      test(
        '$sceneId/$mode: ids are unique across targets and decoys',
        () async {
          final base = await load(sceneId);
          final ids = [
            ...base.targets.map((t) => t.id),
            ...decoysForMode(base, mode).map((d) => d.id),
          ];
          expect(
            ids.toSet(),
            hasLength(ids.length),
            reason: 'Duplicate id in $sceneId/$mode: $ids',
          );
        },
      );

      test('$sceneId/$mode: decoy scales stay within sane bounds', () async {
        // おとりはタップ対象でないためタッチ下限の制約は無いが、画面外へ
        // はみ出したり消えたりする極端値を防ぐためデータ範囲を縛る。
        const minScale = 0.4;
        const maxScale = 1.6;
        final base = await load(sceneId);
        for (final d in decoysForMode(base, mode)) {
          expect(
            d.scale,
            inInclusiveRange(minScale, maxScale),
            reason:
                'Decoy ${d.id} in $sceneId/$mode has scale ${d.scale}, outside '
                '[$minScale, $maxScale]. Keep decoy sizes reasonable.',
          );
        }
      });

      test('$sceneId/$mode: every icon id is a known icon', () async {
        final base = await load(sceneId);
        final unknown = [
          ...base.targets.map((t) => t.iconId),
          ...decoysForMode(base, mode).map((d) => d.iconId),
        ].where((id) => !hasTargetIcon(id)).toSet();

        expect(
          unknown,
          isEmpty,
          reason:
              'Unknown icon id(s) $unknown in $sceneId/$mode render as "?" '
              '(help_outline). Add them to target_icons.dart.',
        );
      });
    }
  }
}
