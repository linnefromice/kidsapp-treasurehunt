/// ホームに並べるシーンの一覧(MVP は scene01 のみ遊べる)。
class SceneCatalogEntry {
  const SceneCatalogEntry(this.id, this.titleKey);
  final String id;
  final String titleKey;
}

const String kFirstSceneId = 'scene01';

const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry('scene01', 'scene.scene01.title'),
  SceneCatalogEntry('scene02', 'scene.scene02.title'),
  SceneCatalogEntry('scene03', 'scene.scene03.title'),
];
