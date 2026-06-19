/// 探し方の難易度。`data/` と `features/` の双方から参照するため `shared/` に置く
/// （`data/` が `features/` を import する逆依存を避ける）。
///
/// - [easy]: シーンが画面ぴったりに収まる（パン不要）。基本おとりのみ。宝は静止。
/// - [normal]: 画面より大きい探索エリア（パンして表示部分をずらす）＋おとり増量。
/// - [hard]: [normal] と同条件 ＋ 未発見の宝が周期的に消える/現れる（点滅）。
enum GameMode { easy, normal, hard }

/// ルートのクエリ（`?mode=`）を [GameMode] に解釈する。
/// `'normal'`→[GameMode.normal] / `'hard'`→[GameMode.hard] /
/// それ以外（未指定・不明含む）→ [GameMode.easy]（最もやさしい既定）。
GameMode gameModeFromQuery(String? raw) => switch (raw) {
  'easy' => GameMode.easy,
  'normal' => GameMode.normal,
  'hard' => GameMode.hard,
  _ => GameMode.easy, // 未指定・不明は最もやさしい既定にフォールバック
};
