import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

/// ホームの宝の地図に並べるシーン。MVP は scene01 のみ最初から解放。
class SceneCatalogEntry {
  const SceneCatalogEntry(this.id, this.titleKey, this.mapPos, this.themeIcon);

  final String id;
  final String titleKey;
  final Offset mapPos; // 0.0–1.0 正規化（マップ上の位置）
  final IconData themeIcon; // 森 / 海 / 空

  bool get hasScene =>
      id == 'scene01' ||
      id == 'scene02' ||
      id == 'scene03' ||
      id == 'scene04' ||
      id == 'scene05' ||
      id == 'scene06' ||
      id == 'scene07' ||
      id == 'scene08' ||
      id == 'scene09';
}

const String kFirstSceneId = 'scene01';

// マップ上の位置は左→右に x を単調増加させた緩やかな波。
// x が常に増えるため連結線が交差せず、シンプルな一本道に見える。
const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry(
    'scene01',
    'scene.scene01.title',
    Offset(0.080, 0.40),
    Icons.park,
  ),
  SceneCatalogEntry(
    'scene02',
    'scene.scene02.title',
    Offset(0.185, 0.64),
    Icons.water,
  ),
  SceneCatalogEntry(
    'scene03',
    'scene.scene03.title',
    Offset(0.290, 0.40),
    Icons.cloud,
  ),
  SceneCatalogEntry(
    'scene04',
    'scene.scene04.title',
    Offset(0.395, 0.64),
    Icons.yard,
  ),
  SceneCatalogEntry(
    'scene05',
    'scene.scene05.title',
    Offset(0.500, 0.40),
    Icons.nights_stay,
  ),
  SceneCatalogEntry(
    'scene06',
    'scene.scene06.title',
    Offset(0.605, 0.64),
    Icons.wb_sunny,
  ),
  SceneCatalogEntry(
    'scene07',
    'scene.scene07.title',
    Offset(0.710, 0.40),
    Icons.rocket_launch,
  ),
  SceneCatalogEntry(
    'scene08',
    'scene.scene08.title',
    Offset(0.815, 0.64),
    Icons.scuba_diving,
  ),
  SceneCatalogEntry(
    'scene09',
    'scene.scene09.title',
    Offset(0.920, 0.40),
    Icons.ac_unit,
  ),
];

/// kSceneCatalog の並び順で次のシーン id。最後 / 未知なら null。
String? nextSceneId(String id) {
  final index = kSceneCatalog.indexWhere((e) => e.id == id);
  if (index < 0 || index + 1 >= kSceneCatalog.length) return null;
  return kSceneCatalog[index + 1].id;
}

/// シーンクリア時の進行処理: クリア記録 + 次シーン解放（最後なら no-op）。
/// 解放チェーンはモードごとに独立した一本道（[GameMode] ごとに別々の進捗）。
Future<void> completeScene(
  ProgressRepository progress,
  GameMode mode,
  String sceneId,
) async {
  await progress.markCleared(mode, sceneId);
  final next = nextSceneId(sceneId);
  if (next != null) {
    await progress.unlock(mode, next);
  }
}
