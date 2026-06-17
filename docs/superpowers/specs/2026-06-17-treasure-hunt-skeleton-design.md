# 宝探しアプリ 基盤スケルトン + 初回プレイ(Tap版) 設計書

- 日付: 2026-06-17
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定(実装計画はこの後 writing-plans で作成)
- 一次根拠:
  - ルート `README.md`(開発方針)
  - `ai-research-pipeline/.../reports/kids-treasure-hunt-game-design-and-features-2026.md`(ゲームデザイン調査)
  - 参考アプリ「隠されているものを見つけよう - Find it Out」

---

## 1. 目的とスコープ

### 1.1 このドキュメントが定義するもの

宝探し(隠しオブジェクト探し)アプリの **基盤スケルトン + 最初の遊べるプレイ(vertical slice)**
を定義する。アプリ雛形・レイヤ構成・状態管理/ルーティング配線・端末ローカル永続化・
子供向けテーマ・宝の地図ホーム・配布CIに加え、**1シーンを実際に遊べる Tap 版コアループ**
(探す→タップで見つける→ジューシーに祝う→図鑑に収納→コンプリート)までを含む。

### 1.2 スコープ外(後続の別 spec で扱う)

- **Dig(なでて掘る)操作** — スクラッチで覆い砂を消す方式。Tap 版で核を固めた後、
  同じシーンの上に内部実装を差し替えで追加する(コアループ・図鑑・進捗は不変)。
- 複数ワールド/多数シーン、本格的なシーンデータ制作(MVP は 1 シーン)
- ヒント自動強化(虫眼鏡/指さし)、スター/カスタマイズ/タイマー等の Should/Could 機能
- 保護者ゲートの算数問題ロジック本体(入口の stub のみ)
- 多言語の全文翻訳(ja/en 疎通に必要な最小キーのみ)
- iOS の CI 配布、IAP、Golden テスト

### 1.3 コアゲームの定義(重要・認識合わせ)

本アプリのコアは **隠しオブジェクト探し(シーク＆ファインド)**。**迷路ではない。**

調査レポートの本命は「Dig × Hidden Object ハイブリッド」だが、**最初のスライスは実装が軽い
Tap 版(見つけてタップ)から始める**。1枚のイラストをピンチ拡大/パンしながら、隠れた宝を
タップして見つけ、図鑑に収める。Dig は同じコアループの上に後から足す。

調査由来の鉄則(年齢 0-5 を土台):
- **失敗を罰しない**(空振りに ×・減点・不快音を出さない)
- **時間制限なし**
- **0-5 は無報酬で成立**(スター/競争/リーダーボードは入れない。むしろ逆効果)
- 発見の瞬間に**多感覚フィードバックを集中**(拡大+キラッ+音)
- 読字に依存しない(絵 + 音 + アニメで誘導)

---

## 2. ゲームプレイ設計(Tap 版 vertical slice)

### 2.1 コアループ

```
宝の地図ホームでシーンを選ぶ(絵だけ。読めなくてOK)
  |
  v シーンに入る
  |
  v 探す: InteractiveViewer でピンチ拡大/パン(参考アプリの「ズームアップ」)
  |
  v 怪しい所をタップ
  |     画面座標 → (InteractiveViewer の Matrix4 逆行列) → シーン座標 → 正規化座標
  |     → Rect.contains で未発見の宝に当たったか判定
  |
  v 見つける! <--- ジューシー演出の山場(拡大 + キラッ + 発見音)
  |
  v 図鑑に収納: 画面下の空き枠がパチンと埋まる
  |
  v まだ残ってる? --はい--> 「探す」に戻る(同じシーン)
  |
  v いいえ(コンプリート) → 紙吹雪 + 完了音 → 進捗が1つ前進(cleared を永続化)
```

### 2.2 仕様の決め打ち(最小化のため)

| 項目 | 決定 |
|---|---|
| シーン数 | 1 ワールド・1 シーン |
| 隠し宝の数 | 3〜5 個(0-5 向けに素直な隠し) |
| 操作 | ピンチ拡大/パン + タップ(1指) |
| 当たり判定 | 宝を正規化Rect(0.0–1.0)で定義 → `Rect.contains` |
| 発見トリガー | 未発見の宝の Rect 内をタップした瞬間 |
| 空振り | 罰しない(何も起きない or 淡い演出のみ) |
| 時間制限 | なし |
| 報酬 | なし(発見と図鑑充填が報酬。スター等は入れない) |
| 図鑑 | 画面下に N 枠。見つけるたび埋まる(進捗可視化を兼ねる) |
| 音 | audioplayers で 発見音 / 完了音(最小) |
| マスコット音声 / 保護者ゲート | スケルトンの stub を流用 |

### 2.3 座標変換とヒット判定(中核ロジック・Unit Test 必須)

1. `GestureDetector.onTapDown` で画面ローカル座標を取得。
2. `InteractiveViewer` の `transformationController.value`(`Matrix4`)を
   `Matrix4.inverted()` で反転し、タップ点をシーン座標に変換。
3. シーンの実描画サイズで割り、0.0–1.0 の正規化座標へ。
4. 各 `FindTarget.normalizedRect` に対し `Rect.contains` で判定。最初に当たった
   未発見ターゲットを「発見」とする。

この変換はズレやすいため `unit/hit_test_test.dart` で必ずテストする。

---

## 3. 技術選定

| 項目 | 採用 | 理由 |
|---|---|---|
| フレームワーク | Flutter(確定) | README方針 |
| コアゲーム描画 | **純 Flutter 標準API**(`InteractiveViewer` / `GestureDetector` / `Matrix4` / `Rect.contains` / `CustomPainter`) | 静止画インタラクション。ゲームループ・物理不要で Flame は過剰 |
| 状態管理 | Riverpod + `riverpod_generator`(`@riverpod` + build_runner) | README方針 |
| ルーティング | go_router | README方針 |
| 永続化 | **shared_preferences**(`data/` の Repository で隠蔽) | バックエンド無し。進捗・解放・設定はキー値で十分。YAGNI |
| 音声 | audioplayers(通信なし・効果音のみ) | Kids規制に抵触しない単機能ヘルパー |
| ローカライズ | `flutter_localizations` + `intl`(ARB) | README方針 |

### 3.1 ゲームエンジン(Flame)を入れない判断

隠しオブジェクト探しは「静止画に対するインタラクティブUI」であり、毎フレームの
スプライト更新・物理・ECS・ワールドカメラを必要としない。これらが必要になった時に限り
Flame を検討する。その場合も差し替えは `seek_find` feature の内部に閉じる。

### 3.2 入れない SDK(Kids 規制・README踏襲)

- Firebase Analytics / Crashlytics(ランタイム収集SDK)
- 行動広告SDK(AdMob行動広告 / AppsFlyer / Adjust / Facebook SDK)
- 位置情報(Google Maps 等)
- `firebase_app_distribution` の**ランタイムSDK**もリリースビルドに埋め込まない
  (※ App Distribution への「配布」自体はCIからのアップロードで行い、SDK埋め込みは不要)

---

## 4. アーキテクチャ

### 4.1 レイヤ構成

```
UI(Widget)  →  Controller(@riverpod)  →  Repository(shared_preferences)
```

- **UI**: 表示とジェスチャのみ。状態は Controller を `watch`/`read`。
- **Controller**: 画面状態・進捗・発見状態の読み書きを仲介。`@riverpod` で生成。
- **Repository**: 永続化の単一窓口。`shared_preferences` をここに隠蔽し、
  将来 DB へ差し替えても上位は無変更にする。

### 4.2 ディレクトリ構成

```
lib/
  main.dart                       # runApp + ProviderScope + 初期化(prefsロード)
  app.dart                        # MaterialApp.router + KidsTheme + l10n 設定
  router.dart                     # go_router: / , /hunt/:sceneId , /settings
  features/
    treasure_map/                 # ホーム=宝の地図(シーン一覧・解放状況)
      treasure_map_screen.dart
      treasure_map_controller.dart
    seek_find/                    # ★コア=隠しオブジェクト探し(Tap版を実装)
      seek_find_screen.dart       # InteractiveViewer + シーン描画 + 図鑑バー
      seek_find_controller.dart   # 発見状態・コンプリート判定
      hit_test.dart               # 座標変換 + Rect.contains(純Dart・テスト対象)
      models/
        scene_def.dart            # SceneDef(id, title, imageAsset, targets)
        find_target.dart          # FindTarget(id, label, normalizedRect)
      widgets/
        collection_bar.dart       # 図鑑(下部の N 枠)
        found_burst.dart          # 発見ジュース演出(拡大+キラッ)
    settings/
      settings_screen.dart        # 言語切替 / 保護者ゲート入口(stub)
  data/
    progress_repository.dart      # 解放/クリア状況(shared_preferences)
    settings_repository.dart      # 言語など(shared_preferences)
  shared/
    audio/
      audio_service.dart          # audioplayers ラッパ(発見音/完了音)
    widgets/
      kids_button.dart            # 最小タッチターゲット 60x60dp
      parental_gate.dart          # 入口のみの stub(本体は後続spec)
    theme/
      kids_theme.dart
      breakpoints.dart            # タブレット横向き判定の閾値
    l10n/
      app_ja.arb
      app_en.arb
assets/
  scenes/
    scene01.(png|jpg)             # MVP の1シーン画像
    scene01.json                  # SceneDef(隠し宝の正規化Rect定義)
  sfx/
    found.(mp3|wav)
    complete.(mp3|wav)
test/
  unit/
    hit_test_test.dart            # ★座標変換 + Rect.contains
    progress_repository_test.dart # 解放/クリアの読み書き(mock prefs)
    settings_repository_test.dart # 言語保存/復元
  widget/
    treasure_map_screen_test.dart # シーンカード描画・ロック表示
    seek_find_screen_test.dart    # タップで発見→図鑑が埋まる→コンプリート
    kids_button_test.dart         # タップ・最小サイズ
```

### 4.3 ルーティング(go_router)

| パス | 画面 | 備考 |
|---|---|---|
| `/` | 宝の地図ホーム | シーンカード一覧(解放/ロック) |
| `/hunt/:sceneId` | シーン画面(Tap版プレイ) | InteractiveViewer + 図鑑バー |
| `/settings` | 設定 | 言語切替 / 保護者ゲート入口(stub) |

### 4.4 データモデル

- `SceneDef { String id; String titleKey; String imageAsset; List<FindTarget> targets; }`
- `FindTarget { String id; String labelKey; Rect normalizedRect; }`
  - `normalizedRect` は 0.0–1.0 正規化座標。
- MVP はシーン定義を `assets/scenes/scene01.json` から読み込む。

### 4.5 永続化キー(shared_preferences)

| キー | 型 | 意味 |
|---|---|---|
| `progress.unlockedSceneIds` | `List<String>`(StringList) | 解放済みシーンID |
| `progress.clearedSceneIds` | `List<String>`(StringList) | クリア済みシーンID |
| `settings.locale` | `String`(`ja`/`en`) | 表示言語 |

初回起動時、`unlockedSceneIds` が空なら先頭シーンを解放した状態で初期化する。
シーン内の「どの宝を見つけたか」はセッション内状態(Controller)で持ち、コンプリート時に
`clearedSceneIds` へ反映する(途中状態の永続化は MVP 外)。

---

## 5. 完成定義(Definition of Done)

1. **宝の地図ホーム**が起動し、シーンカードが3枚程度並ぶ(先頭=解放、他=ロック表示)。
2. 解放済みカード tap → `/hunt/:sceneId` 遷移。
3. **シーン画面**でピンチ拡大/パンでき、隠し宝(3〜5個)をタップで発見できる。
   発見時に 拡大+キラッ+発見音、図鑑枠が埋まる。空振りは罰しない。
4. 全宝発見で 紙吹雪+完了音 → `clearedSceneIds` に永続化 → ホームに戻ると進捗が反映。
5. **設定画面**で ja/en 切替 → アプリ再起動後も保持。
6. 「迷路」は一切登場しない。

---

## 6. 子供向け UX(このスライスで担保する最小限)

- タッチターゲット最小 60×60 dp(`KidsButton`)。発見対象の Rect も小さすぎないよう調整。
- タブレット横向きを第一級サポート(`breakpoints` + `LayoutBuilder`/`OrientationBuilder`)。
- 空振り・誤タップを罰しない。×/減点/不快音を出さない(フェイルセーフ)。
- 保護者ゲートは設定・外部操作の前に挟む「入口(stub)」のみ(本体は後続)。
- 色覚・コントラスト・音声ナビ等の詳細は README §5 に従い後続で深掘り。

---

## 7. ビルド / CI 方針

### 7.1 GitHub Actions — 配布のみ

- ファイル: `.github/workflows/distribute.yml`
- トリガー: `workflow_dispatch`(手動実行)
- 手順: `flutter build apk --release`(または `--profile`)→
  Firebase App Distribution へ **Android APK** をテスター配布
- 必要 Secrets: `FIREBASE_APP_ID` / `FIREBASE_SERVICE_ACCOUNT`(配布権限のサービスアカウントJSON)
- iOS 配布は当面スコープ外(Apple 署名のCI投入が重い。ローカル Xcode で確認)。

### 7.2 ローカル品質チェック(初期はCIに載せない)

- `scripts/check.sh`(または `Makefile`)に集約:
  `dart format --set-exit-if-changed .` / `flutter analyze` / `flutter test`
- 任意で `.git/hooks/pre-commit` の雛形を提供(強制はしない)。
- 後でこのスクリプトをそのまま GitHub Actions のジョブへ昇格できる構成にする。

---

## 8. テスト戦略(このスライス段階)

| 種別 | 対象 |
|---|---|
| Unit | `hit_test`(座標変換 + `Rect.contains`)/ `ProgressRepository` / `SettingsRepository` |
| Widget | 宝の地図ホーム / シーン画面(タップ発見→図鑑充填→コンプリート)/ `KidsButton` |

- `shared_preferences` は `SharedPreferences.setMockInitialValues` でテスト。
- Golden テスト(alchemist)は画面が安定してから導入(ここではスコープ外)。

---

## 9. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| スコープ | 基盤スケルトン + 最初の遊べるプレイ(Tap版 1シーン) |
| コアゲーム | 隠しオブジェクト探し / Tap版から開始(Dig は後続で差し替え追加)※迷路ではない |
| コア実装 | 純 Flutter 標準API(`InteractiveViewer`/`Matrix4`/`Rect.contains`)+ 音は audioplayers |
| 状態管理 / ルーティング | Riverpod(`@riverpod`)/ go_router |
| 永続化 | shared_preferences(`data/` Repository で隠蔽) |
| ゲーム原則 | 失敗を罰しない / 時間制限なし / 0-5 無報酬 / 発見に多感覚集中 |
| CI | GitHub Actions = Firebase App Distribution(Android APK)手動配布のみ |
| ローカル | format / analyze / test をスクリプト化 |
