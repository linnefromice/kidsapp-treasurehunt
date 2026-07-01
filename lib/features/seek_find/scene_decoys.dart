/// シーン（ステージ）ごとの「おとり」アイコンプール。
///
/// 各シーンの JSON はこのプールから themed なおとりを敷いてあり、C2 おとり抽選
/// （`SceneDef.withReseededDecoyIcons`）も同じプールから引き直すことで、リプレイでも
/// テーマが崩れない。プールはそのシーンの宝（targets）とは交差しない（整合性）。
library;

const Map<String, List<String>> _kSceneDecoys = {
  'scene01': [
    'leaf',
    'bird',
    'squirrel',
    'hedgehog',
    'bug',
    'flower',
    'rabbit',
    'pinetree',
    'bee',
    'cloud',
  ], // 森
  'scene02': [
    'fish',
    'anchor',
    'swimmer',
    'umbrella',
    'jellyfish',
    'octopus',
    'sun',
    'cloud',
    'ball',
  ], // 海
  'scene03': [
    'cat',
    'bell',
    'lightbulb',
    'pizza',
    'icecream',
    'key',
    'gift',
    'cloud',
    'bird',
  ], // 街
  'scene04': [
    'leaf',
    'fox',
    'owl',
    'mushroom',
    'acorn',
    'cloud',
    'sun',
    'flag',
    'bug',
  ], // 山
  'scene05': [
    'cloud',
    'bird',
    'leaf',
    'gem',
    'bell',
    'cat',
    'planet',
    'snowflake',
  ], // 夜
  'scene06': [
    'fire',
    'gem',
    'key',
    'bird',
    'flag',
    'star',
    'kite',
    'lightbulb',
  ], // 砂漠
  'scene07': [
    'star',
    'moon',
    'saturn',
    'galaxy',
    'cloud',
    'gem',
    'bell',
    'lightbulb',
  ], // 宇宙
  'scene08': [
    'crab',
    'starfish',
    'anchor',
    'swimmer',
    'bucket',
    'sailboat',
    'gem',
    'sun',
  ], // 海中
  'scene09': [
    'cloud',
    'star',
    'gift',
    'bell',
    'cookie',
    'cat',
    'bird',
    'moon',
    'leaf',
  ], // 雪
  'scene10': [
    'leaf',
    'rabbit',
    'bird',
    'cloud',
    'sun',
    'mushroom',
    'cake',
    'gift',
    'kite',
  ], // 花畑
  'scene11': [
    'flower',
    'bird',
    'leaf',
    'butterfly',
    'bee',
    'gift',
    'star',
    'cake',
    'music',
  ], // 虹丘
  'scene12': [
    'cake',
    'gift',
    'bell',
    'cat',
    'music',
    'lightbulb',
    'fire',
    'star',
    'balloon',
  ], // 城
  'scene13': [
    'moon',
    'rocket',
    'ufo',
    'astronaut',
    'cloud',
    'gem',
    'bell',
    'lightbulb',
  ], // 銀河
  'scene14': [
    'lightbulb',
    'music',
    'gift',
    'umbrella',
    'ball',
    'cat',
    'bird',
    'cloud',
  ], // まち
  'scene15': [
    'flower',
    'sun',
    'music',
    'bell',
    'umbrella',
    'kite',
    'cat',
    'bird',
  ], // おかしのくに
  'scene16': [
    'bird',
    'cat',
    'snake',
    'bee',
    'butterfly',
    'bug',
    'leaf',
    'acorn',
  ], // どうぶつえん
  'scene17': [
    'flag',
    'heart',
    'sun',
    'cake',
    'cookie',
    'umbrella',
    'bell',
    'flower',
  ], // ゆうえんち
};

/// 汎用フォールバック（未知シーン）。
const List<String> _kDefaultDecoys = [
  'leaf',
  'bird',
  'cloud',
  'gem',
  'gift',
  'bell',
];

/// [sceneId] のテーマに合うおとりアイコンプール。
List<String> decoyPoolFor(String sceneId) =>
    _kSceneDecoys[sceneId] ?? _kDefaultDecoys;
