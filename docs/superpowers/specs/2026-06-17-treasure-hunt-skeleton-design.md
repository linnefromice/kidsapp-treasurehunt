# 宝探しアプリ 基盤スケルトン 設計書

- 日付: 2026-06-17
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定(実装計画はこの後 writing-plans で作成)
- 一次根拠: ルート `README.md`(開発方針)/ 参考アプリ「隠されているものを見つけよう - Find it Out」

---

## 1. 目的とスコープ

### 1.1 このドキュメントが定義するもの

宝探し(シーク＆ファインド)アプリの **基盤スケルトン** を定義する。アプリの雛形・
レイヤ構成・状態管理/ルーティングの配線・端末ローカル永続化・子供向けテーマ・
宝の地図ホーム、そして配布CIまでを含む。「動く土台」を最短で立てることが目的。

### 1.2 スコープ外(後続の別 spec で扱う)

- シーク＆ファインドのゲームロジック本体(当たり判定アルゴリズム・採点・ヒント)
- シーンデータ(イラスト資産・お題定義JSON)の本格制作
- 保護者ゲートの算数問題ロジック本体(スケルトンでは入口の stub のみ)
- 多言語の全文翻訳(スケルトンでは ja/en の疎通に必要な最小キーのみ)
- iOS の CI 配布、IAP、Golden テスト

### 1.3 コアゲームの定義(重要・認識合わせ)

本アプリのコアは **シーク＆ファインド(隠し物探し)** である。**迷路ではない。**

1枚の精緻なイラスト(例: Fantasy Forest)を表示し、下部のお題リストにある
オブジェクトを、ピンチ拡大・パンしながら探してタップする。全て見つけるとシーン
クリア → 次シーン解放。ホームは「宝の地図」としてシーン群と解放状況を見せる。

---

## 2. 技術選定

| 項目 | 採用 | 理由 |
|---|---|---|
| フレームワーク | Flutter(確定) | README方針 |
| コアゲーム描画 | **純 Flutter 標準API**(`InteractiveViewer` / `GestureDetector` / `Matrix4` / `Rect.contains` / `CustomPainter`) | 静止画インタラクションでありゲームループ・物理が不要。Flame は過剰 |
| 状態管理 | Riverpod + `riverpod_generator`(`@riverpod` + build_runner) | README方針 |
| ルーティング | go_router | README方針 |
| 永続化 | **shared_preferences**(`data/` の Repository で隠蔽) | バックエンド無し。進捗・解放・設定はキー値で十分。YAGNI |
| 音声 | audioplayers(通信なし・効果音のみ) | Kids規制に抵触しない単機能ヘルパー |
| ローカライズ | `flutter_localizations` + `intl`(ARB) | README方針 |

### 2.1 ゲームエンジン(Flame)を入れない判断

シーク＆ファインドは「静止画に対するインタラクティブUI」であり、毎フレームの
スプライト更新・物理・ECS・ワールドカメラを必要としない。これらが必要になった時
(多数スプライトの常時アニメ、物理、パーティクル大量等)に限り Flame を検討する。
その場合も差し替えは `seek_find` feature の内部に閉じ、上位レイヤには影響しない。

### 2.2 入れない SDK(Kids 規制・README踏襲)

- Firebase Analytics / Crashlytics(ランタイム収集SDK)
- 行動広告SDK(AdMob行動広告 / AppsFlyer / Adjust / Facebook SDK)
- 位置情報(Google Maps 等)
- `firebase_app_distribution` の**ランタイムSDK**もリリースビルドに埋め込まない
  (※ App Distribution への「配布」自体はCIからのアップロードで行い、SDK埋め込みは不要)

---

## 3. アーキテクチャ

### 3.1 レイヤ構成

```
UI(Widget)  →  Controller(@riverpod)  →  Repository(shared_preferences)
```

- **UI**: 表示とジェスチャのみ。状態は Controller を `watch`/`read`。
- **Controller**: 画面状態と進捗の読み書きを仲介。`@riverpod` で生成。
- **Repository**: 永続化の単一窓口。`shared_preferences` をここに隠蔽し、
  将来 DB へ差し替えても上位は無変更にする。

### 3.2 ディレクトリ構成

```
lib/
  main.dart                       # runApp + ProviderScope + 初期化(prefsロード)
  app.dart                        # MaterialApp.router + KidsTheme + l10n 設定
  router.dart                     # go_router: / , /hunt/:sceneId , /settings
  features/
    treasure_map/                 # ホーム=宝の地図(シーン一覧・解放状況)
      treasure_map_screen.dart
      treasure_map_controller.dart
    seek_find/                    # ★コア=隠し物探し(スケルトンは器のみ)
      seek_find_screen.dart       # InteractiveViewer + お題リスト枠 + 戻る
      seek_find_controller.dart   # 見つけた数などの画面状態(器)
      models/
        scene_def.dart            # SceneDef(id, title, imageAsset, targets)
        find_target.dart          # FindTarget(id, label, normalizedRect) ※器
    settings/
      settings_screen.dart        # 言語切替 / 保護者ゲート入口(stub)
  data/
    progress_repository.dart      # 解放/クリア状況(shared_preferences)
    settings_repository.dart      # 言語など(shared_preferences)
  shared/
    widgets/
      kids_button.dart            # 最小タッチターゲット 60x60dp
      parental_gate.dart          # 入口のみの stub(本体は後続spec)
    theme/
      kids_theme.dart
      breakpoints.dart            # タブレット横向き判定の閾値
    l10n/
      app_ja.arb
      app_en.arb
test/
  unit/
    progress_repository_test.dart # 解放/クリアの読み書き(in-memory prefs)
    settings_repository_test.dart # 言語保存/復元
  widget/
    treasure_map_screen_test.dart # シーンカード描画・ロック表示
    kids_button_test.dart         # タップ・最小サイズ
```

### 3.3 ルーティング(go_router)

| パス | 画面 | 備考 |
|---|---|---|
| `/` | 宝の地図ホーム | シーンカード一覧(解放/ロック) |
| `/hunt/:sceneId` | シーン画面の器 | InteractiveViewer + お題リスト枠 |
| `/settings` | 設定 | 言語切替 / 保護者ゲート入口(stub) |

### 3.4 データモデル(スケルトンでの最小形)

- `SceneDef { String id; String titleKey; String imageAsset; List<FindTarget> targets; }`
- `FindTarget { String id; String labelKey; Rect normalizedRect; }`
  - `normalizedRect` は 0.0–1.0 正規化座標(当たり判定の実ロジックは後続spec)
- スケルトンでは `targets` は空または少数のダミーで可。**判定ロジックは実装しない**。

### 3.5 永続化キー(shared_preferences)

| キー | 型 | 意味 |
|---|---|---|
| `progress.unlockedSceneIds` | `List<String>`(StringList) | 解放済みシーンID |
| `progress.clearedSceneIds` | `List<String>`(StringList) | クリア済みシーンID |
| `settings.locale` | `String`(`ja`/`en`) | 表示言語 |

初回起動時、`unlockedSceneIds` が空なら先頭シーンを解放した状態で初期化する。

---

## 4. 画面仕様(スケルトンの完成定義)

中身(ゲームロジック)は空でよいが、以下が「動く」ことを完成の定義とする。

1. **宝の地図ホーム** が起動し、シーンカードが3枚程度並ぶ。先頭=解放、他=ロック表示。
2. 解放済みカード tap → `/hunt/:sceneId` へ遷移。
3. **シーン画面の器**: サンプル画像を `InteractiveViewer` でピンチ拡大/パンできる。
   下部に「お題リスト」の空枠を表示。戻るで `/` に戻れる。
4. **設定画面**で ja/en を切替 → アプリ再起動後も保持(永続化の疎通確認)。
5. **進捗Repository** に「クリア済み」を書ける/読める(実クリア判定は後続spec)。

この段階で「迷路」は一切登場しない。コアは隠し物探しの器である。

---

## 5. 子供向け UX(スケルトンで担保する最小限)

- タッチターゲット最小 60×60 dp(`KidsButton` で担保)。
- タブレット横向きを第一級サポート(`breakpoints` + `LayoutBuilder`/`OrientationBuilder`)。
  - 横長 = シーン画面を広く使う / ホームはカードを多列表示。
- 保護者ゲートは設定・外部操作の前に挟む「入口(stub)」のみ用意(本体は後続)。
- 詳細な UX チェックリスト(色覚・コントラスト・音声ナビ等)は README §5 に従い、
  各 feature 実装の後続 spec で個別に担保する。

---

## 6. ビルド / CI 方針

### 6.1 GitHub Actions — 配布のみ

- ファイル: `.github/workflows/distribute.yml`
- トリガー: `workflow_dispatch`(手動実行)
- 手順: `flutter build apk --release`(または `--profile`)→
  Firebase App Distribution へ **Android APK** をテスター配布
- 必要 Secrets:
  - `FIREBASE_APP_ID`
  - `FIREBASE_SERVICE_ACCOUNT`(App Distribution 配布権限のサービスアカウントJSON)
- iOS 配布は当面スコープ外(Apple 署名のCI投入が重いため。ローカル Xcode で確認)。

### 6.2 ローカル品質チェック(初期はCIに載せない)

- `scripts/check.sh`(または `Makefile`)に集約:
  `dart format --set-exit-if-changed .` / `flutter analyze` / `flutter test`
- 任意で `.git/hooks/pre-commit` の雛形を提供(強制はしない)。
- 後でこのスクリプトをそのまま GitHub Actions のジョブへ昇格できる構成にする。

---

## 7. テスト戦略(スケルトン段階)

| 種別 | 対象 |
|---|---|
| Unit | `ProgressRepository`(解放/クリアの読み書き)/ `SettingsRepository`(言語保存・復元) |
| Widget | 宝の地図ホーム(カード描画・ロック表示)/ `KidsButton`(タップ・最小サイズ) |

- `shared_preferences` は `SharedPreferences.setMockInitialValues` でテストする。
- Golden テスト(alchemist)は画面が出来てから導入するため、ここではスコープ外。

---

## 8. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| スコープ | 基盤スケルトンのみ(ミニゲーム内部は後続spec) |
| コアゲーム | シーク＆ファインド(隠し物探し)※迷路ではない |
| コア実装 | 純 Flutter 標準API(エンジン不要)+ 音は audioplayers |
| 状態管理 / ルーティング | Riverpod(`@riverpod`)/ go_router |
| 永続化 | shared_preferences(`data/` Repository で隠蔽) |
| 画面 | 宝の地図ホーム / シーン画面の器(InteractiveViewer)/ 設定 |
| CI | GitHub Actions = Firebase App Distribution(Android APK)手動配布のみ |
| ローカル | format / analyze / test をスクリプト化 |
