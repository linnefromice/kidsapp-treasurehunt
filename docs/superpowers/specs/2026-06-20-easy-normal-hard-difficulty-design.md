# Easy / Normal / Hard 難易度設計

**日付:** 2026-06-20
**ステータス:** 承認済み（実装着手）
**関連:** `2026-06-17-treasure-hunt-skeleton-design.md`（コアループの正典）

---

## 1. 目的

現行の 2 段（Normal / Hard）を 3 段（**Easy / Normal / Hard**）に再編する。
難易度のレバーを「探す数」から「**探索エリアの広さ**」と「**おとりの量**」に移し、
点滅は最上位だけの演出にする。

| モード | 内容 |
|--------|------|
| **Easy** | = 現行 Normal。シーンが画面ぴったりに収まる。パン不要。基本おとりのみ。宝は静止。 |
| **Normal** | シーンが**画面より大きい**探索エリアになり、**パンして表示部分をずらす**必要がある。おとりを増量。 |
| **Hard** | Normal と同条件 ＋ 現行 Hard の**点滅**（未発見の宝が周期的に消える/現れる）。 |

### 全モード共通（＝ 難易度で変えないもの）

- **探す宝の数は据え置き**（モード間で同じ。現行 Hard の「ダミー→ターゲット昇格」は**廃止**）。
- **宝アイコンの表示サイズは共通**（`kTreasureDisplayScale = 1.15`。現行 Hard の `0.8` 倍縮小は**廃止**）。
- 既存のゲーム設計原則を維持: 失敗を罰しない / 急かさない / 時間制限なし / 無制限ヒント /
  タッチターゲット ≥ 60dp / 消失中の宝タップは無反応。

---

## 2. モードの選択と解放

- **3 モードとも最初から選択可能**（ホームのトグルは Easy / Normal / Hard の 3 チップを常時表示）。
- **シーンの解放はモードごとに独立した一本道**。各モードとも `scene01` のみ解放状態で始まり、
  クリアで次シーンを解放する。モードを切り替えても進捗は混ざらない。
- フリーモード（`kFreeModeSlotId`）は従来どおり全シーン解放。3 モードのトグルも同様に使える。

---

## 3. 「画面より大きいエリア」の実現

- **Easy**: 現行どおりシーン論理キャンバス＝ビューポート（パンなし）。
- **Normal / Hard**: シーン論理キャンバスをビューポートより大きく（係数 `kLargeAreaFactor ≒ 1.7`）描画し、
  `InteractiveViewer` で**パン**できるようにする。
  - `minScale = 1.0`（全体を一望できないよう、これ以上は縮小不可＝必ずパンが要る）。
  - `maxScale`（拡大）はディテール確認用に許可（例 2.5）。
  - `panEnabled: true` / `scaleEnabled: true`。
- 当たり判定は**正規化座標のまま**。`GestureDetector` をシーンキャンバス（`InteractiveViewer` の子）の
  内側に置くので `localPosition` はキャンバス座標になり、`findHitTargetId` はキャンバスサイズを
  `sceneSize` として渡せばそのまま機能する（座標変換の追加は不要）。

---

## 4. おとりの増量

- **Easy**: シーン定義の `dummies` のみをおとりとして描画（現行 Normal と同じ）。
- **Normal / Hard**: `dummies` ＋ `hardDummies` を**すべておとりとして描画**（昇格はしない）。
  - 既存データで scene01 は 6 + 5 = 11 個になり、Easy の 6 個より明確に増える。
  - シーン作者が更におとりを増やしたい場合は `hardDummies` に追記する（データ駆動）。

---

## 5. データモデル（進捗）

`GameMode` enum を `lib/shared/game_mode.dart` に移し、`data/` と `features/` の双方から参照可能にする
（`data/` が feature を import する逆依存を避ける）。

`ProgressRepository` をモード対応にする。**解放・クリアをモードごとに独立管理**する。

| 概念 | Easy（レガシーキー流用＝移行不要） | Normal（新規） | Hard（一部レガシー流用） |
|------|------|------|------|
| 解放 | `progress.<slot>.unlockedSceneIds` | `progress.<slot>.normal.unlockedSceneIds` | `progress.<slot>.hard.unlockedSceneIds` |
| クリア | `progress.<slot>.clearedSceneIds` | `progress.<slot>.normal.clearedSceneIds` | `progress.<slot>.hardClearedSceneIds` |

- Easy は既存キーをそのまま使うため、**既存セーブ（テストスロットの進捗）が保持される**。
- Normal / Hard の解放セットが空のときは `scene01` を初期解放する（スロット生成時に 3 モード分シードし、
  既存スロット救済として空なら遅延シードもする）。
- `clearAll()` は 3 モード分の解放・クリアキーをすべて削除する。

---

## 6. ルーティング

- `GameMode { easy, normal, hard }`。
- `/hunt/:sceneId?mode=easy|normal|hard`。`gameModeFromQuery`: `'normal'→normal` / `'hard'→hard` /
  それ以外（未指定含む）→ `easy`（最もやさしい既定）。
- 解放ゲートは廃止（3 モードとも最初から選べるため、現行の `allScenesCleared` による Hard 降格は不要）。
  ただし未解放シーンへの URL 直打ちは従来どおりホームのノード非活性で UX 上は到達しにくい。

---

## 7. ホーム（宝の地図）

- モードトグルを **3 チップ常時表示**（Easy / Normal / Hard）。`home.modeEasy` を新設。
  ラベル: ja「やさしい / ふつう / むずかしい」、en「Easy / Normal / Hard」。Hard は `🔥` を付す。
- バッジ・クリアカウンタ・一本道（足跡）・現在地は**選択中モードの進捗**を反映する。
- ノードのタップ先は選択中モードに応じて `?mode=` を付ける。

---

## 8. テスト

- **Unit**
  - `gameModeFromQuery`: `'easy'/'normal'/'hard'/null/不明` の 5 経路。
  - おとり合成の純関数（Easy=`dummies` / Normal・Hard=`dummies+hardDummies`、ターゲット数不変）。
  - `ProgressRepository`: モード 3 系統の解放・クリアが独立／`clearAll` が全消し／Easy レガシーキー読み出し。
  - 点滅（`treasureBlinkOpacity` 等）の既存テストは維持。
- **Widget**
  - ホーム: 3 チップ表示、切替で対象モードの進捗反映。
  - シーン: Normal でパン可能・パン後座標で宝発見できるスモーク（座標変換の健全性）。
  - 既存の seek_find widget スモークは skip 方針を踏襲。
- `bash scripts/check.sh`（format / analyze / test）緑を完了条件とする。

---

## 9. 非目標（YAGNI）

- 難易度ごとのスター/スコア/タイム計測（無報酬原則を維持）。
- ピンチズームのカスタム UI（`InteractiveViewer` 標準で足りる）。
- セーブデータの本格マイグレーション機構（キー流用で回避）。
