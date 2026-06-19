import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';

/// 探し方の難易度。通常はやさしい配置、ハードは探す量を増やしアイコンを小さくする。
enum GameMode { normal, hard }

/// ハードモードでの宝アイコン表示スケール（通常は [kTreasureDisplayScale] = 1.15）。
/// 通常の約 7 割サイズ。タブレット横向きでタッチ目標 60dp を概ね維持する範囲。
const double kHardModeDisplayScale = 0.8;

/// ルートのクエリ（`?mode=hard`）を [GameMode] に解釈する。未指定/不明は normal。
GameMode gameModeFromQuery(String? raw) =>
    raw == 'hard' ? GameMode.hard : GameMode.normal;

/// ハードモード用にシーン定義を変換する純粋関数。
///
/// - 既存ダミーをすべて探す対象（[FindTarget]）へ昇格させ、探す量を増やす。
/// - 引っかけ役は [SceneDef.hardDummies]（ハード専用デコイ）に差し替える。
///
/// 元の [SceneDef] は変更せず、新しいインスタンスを返す（イミュータブル）。
SceneDef hardModeSceneDef(SceneDef base) {
  return SceneDef(
    id: base.id,
    titleKey: base.titleKey,
    imageAsset: base.imageAsset,
    targets: [...base.targets, ...base.dummies.map(_dummyAsTarget)],
    dummies: base.hardDummies,
  );
}

/// ダミーを探す対象へ昇格する。表示は iconId 基準なので labelKey は合成で足りる
/// （図鑑バーは iconId で集計するため表示には未使用）。
FindTarget _dummyAsTarget(DummyItem d) => FindTarget(
  id: d.id,
  iconId: d.iconId,
  labelKey: 'target.${d.iconId}',
  normalizedRect: d.normalizedRect,
);
