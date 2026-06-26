/// シーン（ステージ）ごとの「かぶせもの（A1 箱隠し）」プール。
///
/// ステージのイメージに合わせたカバーを 2〜3 種ずつ用意し、各ターゲットに
/// この中からランダムに被せる（`SceneDef.withThemedCovers`）。テーマは背景
/// ペインター（`scene_background.dart`）に対応:
/// 01森 02海 03街 04山 05夜 06砂漠 07宇宙 08海中 09雪 10花畑 11虹丘 12城 13銀河。
library;

const Map<String, List<String>> _kSceneCovers = {
  'scene01': ['cover_leaves', 'cover_bush', 'cover_chest'], // 森
  'scene02': ['cover_shell', 'cover_rock', 'cover_chest'], // 海
  'scene03': ['cover_box', 'cover_bush', 'cover_rock'], // 街
  'scene04': ['cover_rock', 'cover_bush', 'cover_chest'], // 山
  'scene05': ['cover_cloud', 'cover_bush', 'cover_star'], // 夜
  'scene06': ['cover_rock', 'cover_box', 'cover_chest'], // 砂漠
  'scene07': ['cover_cloud', 'cover_star', 'cover_rock'], // 宇宙
  'scene08': ['cover_shell', 'cover_rock', 'cover_bush'], // 海中
  'scene09': ['cover_snow', 'cover_box', 'cover_bush'], // 雪
  'scene10': ['cover_leaves', 'cover_bush', 'cover_chest'], // 花畑
  'scene11': ['cover_cloud', 'cover_bush', 'cover_leaves'], // 虹の丘
  'scene12': ['cover_box', 'cover_chest', 'cover_rock'], // 城
  'scene13': ['cover_cloud', 'cover_star', 'cover_rock'], // 銀河
};

/// 各ターゲットがカバー（箱隠し）で隠れる確率（要望[2]: 体感 ~40%）。
const double kThemedCoverChance = 0.4;

/// 未知シーンのフォールバックプール（汎用の自然物）。
const List<String> _kDefaultCovers = ['cover_box', 'cover_bush'];

/// [sceneId] のテーマに合うカバー id プール。未知 id は汎用にフォールバック。
List<String> coversForScene(String sceneId) =>
    _kSceneCovers[sceneId] ?? _kDefaultCovers;
