# Glossary — kidsapp-treasurehunt

英単語ベースの用語集。各エントリは **英語名**（設計・コードで使う統一呼称）＋ **日本語名**（UI 文言・会話で使う呼称）＋ **説明** で構成する。

---

## ゲームシステム語彙 (Game System Vocabulary)

ゲームの概念・機能を指す際は、以下の呼び名に統一する。

### Treasure Map（宝の地図）
ステージ選択画面。5 つの Scene がマップ上に配置されており、解放済みの Scene をタップして探索を開始する。  
**コード識別子:** `TreasureMapScreen` / ルート `/`

---

### Scene（シーン）
宝探しの 1 エリア（1 ステージ）。1 枚の背景画像と、その中に隠された複数の Treasure で構成される。  
プレイヤーは Scene をピンチ拡大・パンしながら Treasure をタップして発見していく。  
**コード識別子:** `SceneDef`, `scene01`〜`scene05` / ルート `/hunt/:sceneId`

---

### Treasure（お宝）
Scene の中に隠されている「本物の宝」。プレイヤーがタップして発見する対象。  
発見すると Quest Bar のスロットが点灯し、全部見つけると Scene クリアとなる。  
**コード識別子:** `FindTarget`（クラス名）/ JSON フィールド `targets`

---

### Decoy（おとり）
Scene の中に配置されている「偽物の宝」。見た目は Treasure と同じアイコンを使うが、タップしても反応しない。  
プレイヤーが間違えやすくするためのおとり役。  
**コード識別子:** `DummyItem`（クラス名）/ JSON フィールド `dummies`

---

### Quest Bar（クエストバー）
Scene 画面の下部に表示される「探すものの一覧」。各 Treasure のアイコンをスロットとして並べ、発見済みは点灯、未発見はグレーで表示する。  
プレイヤーが「何を探せばいいか」をいつでも確認できるヒントエリア。  
**コード識別子:** `CollectionBar`（クラス名）

---

## シーン一覧 (Scene List)

| Scene ID | 日本語名 | 英語名 |
|----------|----------|--------|
| scene01 | もりのたからさがし | Forest Hunt |
| scene02 | うみのたからさがし | Ocean Hunt |
| scene03 | そらのたからさがし | Sky Hunt |
| scene04 | やまのたからさがし | Mountain Hunt |
| scene05 | よるのたからさがし | Night Hunt |

---

## 補足語彙 (Supplementary Terms)

### Save Slot（セーブスロット）
プレイヤーを区別するセーブデータの枠。固定 3 枠。  
起動時にアバターを選んでスロットを決める。進捗（解放・クリア状態）はスロットごとに独立。  
**コード識別子:** `SaveSlot`（クラス名）/ `slot1`〜`slot3`

### Unlock（解放）
ロックされていた Scene が遊べるようになること。前の Scene をクリアすると次の Scene が解放される。  
**コード識別子:** `ProgressRepository.unlock()`

### Clear（クリア）
Scene 内の全 Treasure を発見した状態。クリア時にキラキラアニメーション（Clear Overlay）が表示される。  
**コード識別子:** `ProgressRepository.markCleared()`

### Parental Gate（保護者ゲート）
設定変更・スロットリセットなど子供に誤操作させたくない操作の前に表示する、算数問題による認証ダイアログ。  
**コード識別子:** `ParentalGate`（ウィジェット名）

---

## 呼び名の対応表 (Name Mapping)

設計・会話・コード間での呼び名の対応をまとめる。

| ゲーム設計での呼び名 | UI 上の日本語 | コード識別子 |
|----------------------|-------------|-------------|
| Treasure Map | 宝の地図 | `TreasureMapScreen` |
| Scene | シーン | `SceneDef`, `scene01`〜 |
| Treasure | お宝 | `FindTarget` |
| Decoy | おとり | `DummyItem` |
| Quest Bar | クエストバー | `CollectionBar` |
| Save Slot | セーブスロット | `SaveSlot`, `slot1`〜 |
