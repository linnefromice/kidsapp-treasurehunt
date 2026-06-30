/// 探し方の難易度。`data/` と `features/` の双方から参照するため `shared/` に置く
/// （`data/` が `features/` を import する逆依存を避ける）。
///
/// 能力は 3 つの軸（スクロール / 点滅 / 残機）の組み合わせで表す:
/// | mode   | scrolls | blinks | hasLives |
/// |--------|:---:|:---:|:---:|
/// | easy   |  ✗  |  ✗  |  ✗  |
/// | normal |  ✗  |  ✓  |  ✗  |
/// | hard   |  ✓  |  ✓  |  ✗  |
/// | pro    |  ✓  |  ✓  |  ✓  |
///
/// - [easy]: シーンが画面ぴったりに収まる（パン不要）。宝は静止。
/// - [normal]: 画面ぴったり ＋ 未発見の宝が周期的に消える/現れる（点滅）。
/// - [hard]: 画面より大きい探索エリア（パン/拡大）＋ 点滅。
/// - [pro]: [hard] と同条件 ＋ **残機**（おとりタップで誤答＝失点。pro のみ no-fail を外す）。
enum GameMode {
  easy,
  normal,
  hard,
  pro;

  /// 画面より大きい探索エリアをパン/拡大して探すか（hard / pro）。
  bool get scrolls => this == GameMode.hard || this == GameMode.pro;

  /// 未発見の宝が周期的に消える/現れる（点滅）か（normal / hard / pro）。
  bool get blinks => this != GameMode.easy;

  /// 残機（おとりタップで誤答＝失点）を持つか（pro のみ）。
  bool get hasLives => this == GameMode.pro;
}

/// ルートのクエリ（`?mode=`）を [GameMode] に解釈する。
/// 既知の名前に一致すればそのモード、それ以外（未指定・不明含む）は
/// [GameMode.easy]（最もやさしい既定）にフォールバックする。
GameMode gameModeFromQuery(String? raw) => switch (raw) {
  'normal' => GameMode.normal,
  'hard' => GameMode.hard,
  'pro' => GameMode.pro,
  _ => GameMode.easy, // 'easy'・未指定・不明はすべて最もやさしい既定
};
