# Glossary — kidsapp-treasurehunt

英単語ベースの用語集。各エントリは **英語名**（設計・コードで使う統一呼称）＋ **日本語名**（UI 文言・会話で使う呼称）＋ **説明** で構成する。

---

## ゲームシステム語彙 (Game System Vocabulary)

ゲームの概念・機能を指す際は、以下の呼び名に統一する。

### Treasure Map（宝の地図）
ステージ選択画面。羊皮紙風の世界地図に **9 つの Scene** が曲線ルート（足跡つき）で配置されており、
解放済みの Scene をタップして探索を開始する。全クリア後は Normal / Hard を切り替えるトグルが出る。  
**コード識別子:** `TreasureMapScreen` / ルート `/`

---

### Scene（シーン）
宝探しの 1 エリア（1 ステージ）。1 枚の背景（生きた環境アニメ）と、その中に隠された複数の Treasure で構成される。  
プレイヤーは Scene をピンチ拡大・パンしながら Treasure をタップ（または指/ペンでなぞって）発見していく。  
**コード識別子:** `SceneDef`, `scene01`〜`scene13` / ルート `/hunt/:sceneId`（`?mode=hard` で難化）

---

### Treasure（お宝）
Scene の中に隠されている「本物の宝」。プレイヤーがタップして発見する対象。  
発見すると Quest Bar のスロットが点灯し、全部見つけると Scene クリアとなる。  
**コード識別子:** `FindTarget`（クラス名）/ JSON フィールド `targets`

---

### Decoy（おとり）
Scene の中に配置されている「偽物の宝」。タップしても反応しない、紛らわしさを出すためのおとり役。  
**同一シーン内では Treasure とは別アイコンを使う**（同じアイコンだと「宝そっくりだが当たり判定外」になり
「N 個さがす」が破綻するため。`scene_consistency_test` が排他を強制）。Normal / Hard では `hardDummies` も加わり量が増える。  
**コード識別子:** `DummyItem`（クラス名）/ JSON フィールド `dummies` / `hardDummies`

---

### Quest Bar（クエストバー）
Scene 画面の下部に表示される「探すものの一覧」。各 Treasure のアイコンをスロットとして並べ、発見済みは点灯、未発見はグレーで表示する。  
プレイヤーが「何を探せばいいか」をいつでも確認できるヒントエリア。  
**コード識別子:** `CollectionBar`（クラス名）

---

## シーン一覧 (Scene List)

| Scene ID | 日本語名 | 英語名 |
|----------|----------|--------|
| scene01 | もりの たからさがし | Forest Hunt |
| scene02 | うみの たからさがし | Ocean Hunt |
| scene03 | そらの たからさがし | Sky Hunt |
| scene04 | やまの たからさがし | Mountain Hunt |
| scene05 | よるの たからさがし | Night Hunt |
| scene06 | さばくの たからさがし | Desert Hunt |
| scene07 | うちゅうの たからさがし | Space Hunt |
| scene08 | うみのなかの たからさがし | Undersea Hunt |
| scene09 | ゆきやまの たからさがし | Snowy Hunt |
| scene10 | はなばたけの たからさがし | Flower Field Hunt |
| scene11 | にじのおかの たからさがし | Rainbow Hills Hunt |
| scene12 | おしろの たからさがし | Castle Hunt |
| scene13 | ぎんがの たからさがし | Galaxy Hunt |

---

## 補足語彙 (Supplementary Terms)

### Save Slot（セーブスロット）
プレイヤーを区別するセーブデータの枠。固定 3 枠。空きスロットは白紙で、開始時に**絵文字アバター**
（`kAvatarEmojis` の白リストから選択）を決めてスロットを作成する。進捗（解放・クリア状態）はスロットごとに独立。  
**コード識別子:** `SaveSlot`（クラス名）/ `slot1`〜`slot3` / アバターは `save.avatar.<slotId>` に永続化

### Game Mode（ゲームモード）
Scene の難易度。`normal`（既定）と `hard`。`/hunt/:sceneId?mode=hard` で指定し、URL 直打ちでも
全クリア未達なら自動で normal に降格する。  
**コード識別子:** `GameMode`（enum, `hard_mode.dart`）

### Hard Mode（むずかしいモード）
高難度モード。Normal と同じく探索エリアが画面より広く（パン必須）、`SceneDef.dummies` ＋ `SceneDef.hardDummies` で
おとりが増える（※「ダミーがターゲットに昇格」する旧仕様は廃止済み）。さらに **未発見の宝もおとりも周期的に消えたり
現れたりする（点滅）**。失敗を罰しない原則は維持（消失中の宝のタップは無反応・残り 1 つは点滅停止）。
進捗は Normal と混ざらないよう `#hard` で名前空間化する。  
**コード識別子:** `decoysForMode()` / `treasureBlinkOpacity()` / `kBlinkCyclePeriod` / `completeScene(progress, GameMode.hard, ...)`

### Free Mode（フリーモード）
全 Scene が最初から解放された練習モード。3 つの実スロットとは別の専用枠で、進捗キーが独立する（`progress.free.*`）。  
**コード識別子:** `kFreeModeSlotId`（`'free'`）/ UI 文言「フリーモード」

### Idle Hint（アイドルヒント）
一定時間（8 秒）無操作が続くと、未発見の Treasure が 1 つわずかに光って場所を示す。操作のたびにリセットされ急かさない。  
**コード識別子:** `pickHintTargetId()` / `HintGlow`（ウィジェット名）

### Living Background（生きた背景）
Scene の背景に施した環境アニメ（葉のゆらぎ・波・星のまたたき等）。静止画より発見の楽しさを高める。  
**コード識別子:** `scene_background.dart`

### Miss Bubble（ミスバブル）
何も無い場所を**タップ**したときに出る、控えめな反応（罰ではない）。Treasure 発見やヒントとは別物。  
消失中の Treasure（Hard Mode の点滅）をタップした場合は**出さない**。なぞり（ドラッグ）中も出さず、代わりに Trail Sparkle を出す。  
**コード識別子:** `MissBubble`（ウィジェット名）

### Trail Sparkle（なぞりキラキラ）
Easy Mode で**なぞった（ドラッグした）**指先に追従して出る、一瞬の小さなキラキラ粒子。色は設定の Trail Style / Trail Color で決まる。  
発見の有無に関わらず指の動きに付くなぞり演出で、タップ時の Miss Bubble とは別物。  
**コード識別子:** `TrailSparkle`（ウィジェット名） / `TrailColorChoice`（色） / `resolveTrailColor`

### Trail Style（なぞりの いろの 種類）
なぞりキラキラの描き方。**たんしょく（単色）** / **にじ（3しょく）**（選んだ 3 色を粒ごとに循環） / **にじ（フル）**（色相を一周）の 3 種類。  
単色・にじ3色とも `TrailColorChoice` のパレット（現在 **20 色**）から選ぶ。にじ3色は設定でドロップダウン 3 つから色を選ぶ（重複可）。
スタイル・単色・3 色はそれぞれ独立に永続化され全スロット共通。  
**コード識別子:** `TrailStyle` / `TrailColorChoice`（20 色）/ `TrailSetting` / `resolveTrailColor`

### Unlock（解放）
ロックされていた Scene が遊べるようになること。前の Scene をクリアすると次の Scene が解放される。  
**コード識別子:** `ProgressRepository.unlock()`

### Clear（クリア）
Scene 内の全 Treasure を発見した状態。クリア時に紙吹雪＋キラキラの演出（Clear Overlay）が表示される。  
**コード識別子:** `completeScene(progress, mode, sceneId)` / `ProgressRepository.markCleared(mode, sceneId)`（モードごとに名前空間化）

### Parental Gate（保護者ゲート）
設定変更・スロットリセットなど子供に誤操作させたくない操作の前に表示する、算数問題による認証ダイアログ。  
**コード識別子:** `ParentalGate`（ウィジェット名）

### Collection（図鑑 / コレクション）
発見した Treasure を **スロット単位で永続化**し、横断的に眺める専用画面（`/collection`）。収集の単位は
**ワールド × アイコン**（`sceneId:iconId`・モード非依存）。未収集は影絵（グレーのシルエット）、収集でカラー化し、
初発見には new! バッジが付く。先頭に「あつめた n/total」の収集プログレスを表示。シーン内の Quest Bar
（`CollectionBar`・セッション内インメモリ）とは別物で、こちらは永続。  
**コード識別子:** `CollectionScreen` / `CollectionRepository`（`collection.<slot>.discovered` / `.unseen`）

### Combo / Grand Finale（連鎖演出 / ラスト演出）
連続発見で発見バースト（`FoundBurst`）が段階的に派手になる演出（連鎖）。空振りで静かにリセットするだけで罰しない。
シーンを完成させる「最後の 1 個」は連鎖上限より豪華なグランドフィナーレにする。クリア画面には一度だけ紙吹雪が降る。  
**コード識別子:** `comboBurstScale()` / `kGrandFinaleBurstIntensity` / `FoundBurst.intensity` / `_ConfettiPainter`

### Replay Shuffle（配置シャッフル）
クリア済みシーンの再訪、またはフリーモードで、入場時に宝・おとりの**中心座標を入れ替えて**毎回ちがう配置にする
（id・アイコン・サイズ・難度は不変・初回クリアは安定配置）。  
**コード識別子:** `SceneDef.withShuffledPositions()`

### Move / Trace Toggle（うごかす / なぞる トグル）
Normal / Hard（探索エリアが画面より広いモード）で、1 本指ドラッグの用途を「地図を動かす（パン）」か
「なぞって探す」かを子ども自身が切り替える UI。タップ発見は両モードで常時有効。  
**コード識別子:** `SceneInteraction` / `dragBehaviorFor()`

---

## 呼び名の対応表 (Name Mapping)

設計・会話・コード間での呼び名の対応をまとめる。

| ゲーム設計での呼び名 | UI 上の日本語 | コード識別子 |
|----------------------|-------------|-------------|
| Treasure Map | 宝の地図 | `TreasureMapScreen` |
| Scene | シーン | `SceneDef`, `scene01`〜`scene13` |
| Treasure | お宝 | `FindTarget` |
| Decoy | おとり | `DummyItem` |
| Quest Bar | クエストバー（シーン内・セッション） | `CollectionBar` |
| Collection | たからの ずかん（永続・横断） | `CollectionScreen`, `CollectionRepository` |
| Save Slot | セーブスロット | `SaveSlot`, `slot1`〜 |
| Game Mode | （内部） | `GameMode` |
| Hard Mode | むずかしいモード | `decoysForMode`, `treasureBlinkOpacity` |
| Free Mode | フリーモード | `kFreeModeSlotId` |
| Move / Trace | うごかす / なぞる | `SceneInteraction`, `dragBehaviorFor` |
| Idle Hint | （ヒント光） | `pickHintTargetId` / `HintGlow` |
| Miss Bubble | （空振り反応） | `MissBubble` |
| Trail Sparkle | なぞりキラキラ | `TrailSparkle` |
| Trail Color | なぞった ときの いろ | `TrailColorChoice`（20 色） |
| Trail Style | なぞりの いろの 種類 | `TrailStyle`, `TrailSetting` |
| Replay Shuffle | 配置シャッフル | `SceneDef.withShuffledPositions` |
