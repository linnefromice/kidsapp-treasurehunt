# Glossary — kidsapp-treasurehunt

英単語ベースの用語集。各エントリは **英語ラベル**（コード上の識別子）+ **日本語説明** で構成する。

---

## ドメインモデル (Domain Models)

### Scene
シーン（ゲームステージ）。1 枚の背景画像＋複数の隠し宝で構成されるゲームの 1 ステージ。  
例: `scene01`（もりのたからさがし）〜 `scene05`（よるのたからさがし）。

### SceneDef
`SceneDef` クラス（`lib/features/seek_find/models/scene_def.dart`）。  
JSON アセット（`assets/scenes/<sceneId>.json`）から非同期ロードされる、シーンの実行時定義。  
フィールド: `id`, `titleKey`, `imageAsset`, `targets: List<FindTarget>`, `dummies: List<DummyItem>`。  
→ マップ上の静的メタデータは **SceneCatalogEntry** が担う（役割分担に注意）。

### SceneCatalogEntry
`SceneCatalogEntry` クラス（`lib/scenes_catalog.dart`）。  
宝の地図ホーム画面にシーンノードを並べるための静的定義。Dart 定数として `kSceneCatalog` に格納。  
フィールド: `id`, `titleKey`, `mapPos`（0.0–1.0 正規化座標）, `themeIcon`（地図上のアイコン）。

### FindTarget
`FindTarget` クラス（`lib/features/seek_find/models/find_target.dart`）。  
シーン内の「本物の隠し宝」1 個。プレイヤーがタップで発見する対象。  
フィールド: `id`（例: `heart`）, `labelKey`（翻訳キー）, `normalizedRect`（0.0–1.0 正規化 Rect）。

### DummyItem
`DummyItem` クラス（`lib/features/seek_find/models/dummy_item.dart`）。  
シーン内に配置される「偽物の宝」。見た目は FindTarget と同じ Material Icon を使うが、  
**ヒット判定（`findHitTargetId`）の対象外**。プレイヤーを混乱させるおとり役。  
フィールド: `id`, `iconId`（`_kTargetIcons` のキー）, `normalizedRect`。

### normalizedRect
`Rect` 型の 0.0–1.0 正規化座標で表した矩形。`left`, `top`, `width`, `height` がすべて画面幅・高さに対する相対値。  
画面サイズに依存しないため、タブレット・iPad でリサイズしても当たり判定がズレない。

### SaveSlot
`SaveSlot` クラス（`lib/save_slots_catalog.dart`）。  
固定 3 スロットのセーブ枠の静的定義。フィールド: `id`（`slot1`〜`slot3`）, `avatar`（アイコン）。  
ゲームデータ（進捗）は **ProgressRepository** が別途管理。

---

## ゲームメカニクス (Game Mechanics)

### Seek & Find
コアゲームループ。1 枚のシーンをタップして隠し宝を全部見つけるゲームタイプ。  
「シークアンドファインド」「隠しオブジェクト探し」とも呼ぶ。本アプリの MVP コアゲーム。

### Hit Detection / Hit Test
ヒット判定（`lib/features/seek_find/seek_find_logic.dart` の `findHitTargetId`）。  
`GestureDetector` から取得した `localPosition` を normalizedRect と照合し、  
タップが FindTarget に当たったか判定する。DummyItem は対象外。

### Unlock
シーンの解放。前のシーンをクリアすると次のシーンが解放される連鎖ロック機構。  
`ProgressRepository.unlock(sceneId)` で永続化。初回起動時は `scene01` だけが解放済み。

### Clear
シーンクリア。シーン内の全 FindTarget を発見した状態。`ProgressRepository.markCleared(sceneId)` で記録。  
クリア後に `ClearOverlay`（キラキラアニメーション）が表示され、次シーンが Unlock される。

### completeScene
`kSceneCatalog` での「クリア記録＋次シーン解放」をまとめた手続き（`lib/scenes_catalog.dart`）。  
`markCleared` と `unlock(next)` を 1 回の呼び出しで行う。

---

## 画面 (Screens)

### SlotSelectScreen
スロット選択画面（`lib/features/save_slots/slot_select_screen.dart`）。  
起動直後に表示される（初期ルート: `/slots`）。プレイヤー（SaveSlot）を選んでゲームを開始する。  
未作成スロットは「あたらしく」、作成済みスロットは「つづき」を表示。

### TreasureMapScreen
宝の地図ホーム画面（`lib/features/treasure_map/treasure_map_screen.dart`）。  
ルート: `/`。`kSceneCatalog` を元にシーンノードを配置した地図を表示。  
解放済みシーンのノードをタップすると SeekFindScreen へ遷移。

### SeekFindScreen
シーン探索画面（`lib/features/seek_find/seek_find_screen.dart`）。  
ルート: `/hunt/:sceneId`。シーン背景＋配置アイテム＋コレクションバー＋クリアオーバーレイで構成。

### SettingsScreen
設定画面（`lib/features/settings/settings_screen.dart`）。  
ルート: `/settings`。言語切り替えなどを行う。保護者ゲート経由でアクセス。

---

## UI ウィジェット (UI Widgets)

### CollectionBar
コレクションバー（`lib/features/seek_find/widgets/collection_bar.dart`）。  
シーン画面下部に表示する「お題一覧」バー。見つかった宝は点灯（アンバー色）、未発見はグレー。

### FoundBurst
発見バースト演出ウィジェット（`lib/features/seek_find/widgets/found_burst.dart`）。  
FindTarget をタップ発見した瞬間にアイコン上に重ねて表示。  
`OverflowBox(160×160)` + `_BurstPainter`（拡大リング＋外スパーク 8 本＋内スパーク 8 本）で構成。  
アニメーション完了後はアイコンが透明（`_iconFade` end=0.0）になり、発見済みアイコンを隠さない。

### ClearOverlay（`_ClearOverlay`）
クリアオーバーレイ（`lib/features/seek_find/seek_find_screen.dart` 内のプライベートウィジェット）。  
全 FindTarget 発見時に全画面に表示される完了演出。  
ダーク半透明グラジエント背景＋23 個のきらめく星（`_SparklePainter`）＋クリアメッセージ＋「ちずにもどる」ボタン。

### KidsButton
子供向けボタン（`lib/shared/widgets/kids_button.dart`）。  
最小タッチターゲット 60 dp を確保した共通ボタンウィジェット。

### ParentalGate
保護者ゲート（`lib/shared/widgets/parental_gate.dart`）。  
設定・リセットなど子供が誤操作するべきでない操作の前に表示する算数問題ダイアログ。

### MapNode（`_MapNode`）
地図ノード（`TreasureMapScreen` 内のプライベートウィジェット）。  
宝の地図上に配置されるシーン選択ボタン。解放済みノードはパルスアニメーションで点滅。

### TrailPainter（`_TrailPainter`）
地図の道筋（`TreasureMapScreen` 内のプライベートウィジェット）。  
シーンノードを結ぶ点線パスを `CustomPainter` で描画する。

---

## ビジュアルシステム (Visual System)

### sceneBackground
シーン背景生成関数（`lib/features/seek_find/scene_background.dart`）。  
`sceneId` を受け取り、シーンに対応した `CustomPaint` ウィジェットを返す。  
シーンごとに専用の `CustomPainter` サブクラスが存在する（例: `_ForestPainter`, `_NightPainter`）。

### ScenePainter
各シーン専用の `CustomPainter` サブクラスの総称。  
`lib/features/seek_find/scene_background.dart` 内に定義。  
scene01=`_ForestPainter`, scene02=`_OceanPainter`, scene03=`_SkyPainter`,  
scene04=`_MountainPainter`, scene05=`_NightPainter`。

### targetIcon / targetColor
宝 id → アイコン/色のルックアップ（`lib/features/seek_find/target_icons.dart`）。  
`CollectionBar` とシーン上の `_TargetView` の両方が共用し、見た目を一致させる。  
`_kTargetIcons`, `_kTargetColors` の 2 つの定数マップで管理。

### KidsTheme
子供向け Material3 テーマ（`lib/shared/theme/kids_theme.dart`）。  
アンバー色 (`#FFA000`) をシードカラーとした `ColorScheme.fromSeed`。  
`minTouchTarget = 60`（dp）をクラス定数として定義。

---

## データ層 (Data Layer)

### ProgressRepository
進捗 Repository（`lib/data/progress_repository.dart`）。  
解放シーン ID リスト / クリアシーン ID リスト を `SharedPreferences` に保存する。  
キーはセーブスロット単位で名前空間化: `progress.<slotId>.unlockedSceneIds`。

### SaveSlotRepository
スロット管理 Repository（`lib/data/save_slot_repository.dart`）。  
「どのスロットが作成済みか」を `SharedPreferences` に保存。

### SettingsRepository
設定 Repository（`lib/data/settings_repository.dart`）。  
言語コード（`ja`/`en`）などのアプリ設定を `SharedPreferences` に保存。

---

## Riverpod プロバイダ (Providers)

### activeSlotProvider
現在選択中のセーブスロット id を持つプロバイダ（`providers.dart`）。  
未選択は `null`。ルーターの redirect で未選択時に `/slots` へ強制遷移させる。

### foundControllerProvider
シーン内で発見した宝 id の集合（`providers.dart`）。  
`sceneId` をキーとした `autoDispose.family` Notifier。シーンを離れると自動破棄。

### progressRepositoryProvider
アクティブスロットにスコープした `ProgressRepository`（`providers.dart`）。  
`activeSlotProvider` を監視し、スロット切り替えに追随する。

### sceneProvider
`SceneDef` の非同期ロードプロバイダ（`providers.dart`）。  
`sceneId` をキーとした `FutureProvider.family`。JSON アセットを非同期でロード。

### localeControllerProvider
表示言語（`Locale`）を管理する Notifier（`providers.dart`）。  
`SettingsRepository` で永続化し、`tr()` 関数と連携する。

---

## ルーティング (Routing)

| ルート | 画面 | 説明 |
|--------|------|------|
| `/slots` | SlotSelectScreen | 起動初期画面・スロット選択 |
| `/` | TreasureMapScreen | 宝の地図ホーム |
| `/hunt/:sceneId` | SeekFindScreen | シーン探索 |
| `/settings` | SettingsScreen | 設定 |

未選択スロット状態で `/` 以下へ遷移しようとすると `/slots` にリダイレクト。

---

## インフラ / ツール (Infrastructure)

### fvm (Flutter Version Management)
Flutter SDK バージョン管理ツール。`.fvmrc` が唯一のバージョン真実源。  
コマンドは必ず `fvm flutter ...` / `fvm dart ...` を使う（素の `flutter` は使わない）。

### go_router
Flutter の宣言的ルーティングパッケージ。`routerProvider` で管理。

### Riverpod
状態管理パッケージ。本 MVP は手動 `Notifier`/`Provider`（コード生成なし）。

### shared_preferences
端末ローカルの Key-Value ストレージ。進捗・設定・スロット情報の永続化に使用。  
バックエンドサーバーは一切使わない完全ローカル設計。

### audioplayers
効果音再生パッケージ。通信なし・効果音のみ。`AudioService` インターフェース経由で使用。

### kFirstSceneId
最初に解放されるシーン id を示す定数（`'scene01'`）。`lib/scenes_catalog.dart` で定義。
