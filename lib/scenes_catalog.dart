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

  /// このエントリに実プレイ可能なシーン（JSON + 背景）があるか。
  bool get hasScene => _kPlayableSceneIds.contains(id);
}

/// 実装済みシーン id（JSON・背景ペインター・デコイ/カバー完備）。
/// シーン追加時はここにも足す。
const Set<String> _kPlayableSceneIds = {
  'scene01',
  'scene02',
  'scene03',
  'scene04',
  'scene05',
  'scene06',
  'scene07',
  'scene08',
  'scene09',
  'scene10',
  'scene11',
  'scene12',
  'scene13',
  'scene14',
  'scene15',
  'scene16',
  'scene17',
  'scene18',
  'scene19',
  'scene20',
  'scene21',
};

const String kFirstSceneId = 'scene01';

// マップ上の位置は左→右に x を単調増加させた緩やかな波。
// x が常に増えるため連結線が交差せず、シンプルな一本道に見える。
// 21 シーンを 0.060–0.940 に等間隔配置し、y を 0.40 / 0.64 で交互させる。
const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry(
    'scene01',
    'scene.scene01.title',
    Offset(0.060, 0.40),
    Icons.park,
  ),
  SceneCatalogEntry(
    'scene02',
    'scene.scene02.title',
    Offset(0.104, 0.64),
    Icons.water,
  ),
  SceneCatalogEntry(
    'scene03',
    'scene.scene03.title',
    Offset(0.148, 0.40),
    Icons.cloud,
  ),
  SceneCatalogEntry(
    'scene04',
    'scene.scene04.title',
    Offset(0.192, 0.64),
    Icons.yard,
  ),
  SceneCatalogEntry(
    'scene05',
    'scene.scene05.title',
    Offset(0.236, 0.40),
    Icons.nights_stay,
  ),
  SceneCatalogEntry(
    'scene06',
    'scene.scene06.title',
    Offset(0.280, 0.64),
    Icons.wb_sunny,
  ),
  SceneCatalogEntry(
    'scene07',
    'scene.scene07.title',
    Offset(0.324, 0.40),
    Icons.rocket_launch,
  ),
  SceneCatalogEntry(
    'scene08',
    'scene.scene08.title',
    Offset(0.368, 0.64),
    Icons.scuba_diving,
  ),
  SceneCatalogEntry(
    'scene09',
    'scene.scene09.title',
    Offset(0.412, 0.40),
    Icons.ac_unit,
  ),
  SceneCatalogEntry(
    'scene10',
    'scene.scene10.title',
    Offset(0.456, 0.64),
    Icons.local_florist,
  ),
  SceneCatalogEntry(
    'scene11',
    'scene.scene11.title',
    Offset(0.500, 0.40),
    Icons.looks,
  ),
  SceneCatalogEntry(
    'scene12',
    'scene.scene12.title',
    Offset(0.544, 0.64),
    Icons.castle,
  ),
  SceneCatalogEntry(
    'scene13',
    'scene.scene13.title',
    Offset(0.588, 0.40),
    Icons.auto_awesome,
  ),
  SceneCatalogEntry(
    'scene14',
    'scene.scene14.title',
    Offset(0.632, 0.64),
    Icons.location_city,
  ),
  SceneCatalogEntry(
    'scene15',
    'scene.scene15.title',
    Offset(0.676, 0.40),
    Icons.cake,
  ),
  SceneCatalogEntry(
    'scene16',
    'scene.scene16.title',
    Offset(0.720, 0.64),
    Icons.pets,
  ),
  SceneCatalogEntry(
    'scene17',
    'scene.scene17.title',
    Offset(0.764, 0.40),
    Icons.attractions,
  ),
  SceneCatalogEntry(
    'scene18',
    'scene.scene18.title',
    Offset(0.808, 0.64),
    Icons.fire_truck,
  ),
  SceneCatalogEntry(
    'scene19',
    'scene.scene19.title',
    Offset(0.852, 0.40),
    Icons.directions_boat,
  ),
  SceneCatalogEntry(
    'scene20',
    'scene.scene20.title',
    Offset(0.896, 0.64),
    Icons.toys,
  ),
  SceneCatalogEntry(
    'scene21',
    'scene.scene21.title',
    Offset(0.940, 0.40),
    Icons.shopping_cart,
  ),
];

/// kSceneCatalog の並び順で次のシーン id。最後 / 未知なら null。
String? nextSceneId(String id) {
  final index = kSceneCatalog.indexWhere((e) => e.id == id);
  if (index < 0 || index + 1 >= kSceneCatalog.length) return null;
  return kSceneCatalog[index + 1].id;
}

/// シーンクリア時の進行処理: クリア記録 + 次シーン解放（最後なら no-op）。
///
/// クリアしたモードに加え、**それより やさしいモードも「クリア済み」＋次シーン解放**
/// にする（むずかしいを通せば やさしい/ふつう も達成扱い）。より難しいモード側には
/// 影響しない。`GameMode` は easy < normal < hard の順（index で判定）。
Future<void> completeScene(
  ProgressRepository progress,
  GameMode mode,
  String sceneId,
) async {
  final next = nextSceneId(sceneId);
  for (final m in GameMode.values) {
    if (m.index > mode.index) continue; // より難しいモードは触らない
    await progress.markCleared(m, sceneId);
    if (next != null) {
      await progress.unlock(m, next);
    }
  }
}
