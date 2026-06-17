# kidsapp-treasurehunt

子供向けの **2D 宝探しアプリ**（シーク＆ファインド = 隠しオブジェクト探し）。
Android タブレット / iPad 向けに **Flutter** で個人開発する。

> **コアは「シーク＆ファインド（タップで探す）」。迷路ではない。**
> 1 枚のシーンをピンチ拡大/パンしながら隠し宝を探してタップ → 図鑑に収納 →
> 全部見つけてコンプリート → 次のエリアが開く。

**設計と開発の入口**

| 種類 | 場所 |
|---|---|
| 現行のゲーム/実装設計（正典） | `docs/superpowers/specs/2026-06-17-treasure-hunt-skeleton-design.md` |
| 実装計画（TDD タスク） | `docs/superpowers/plans/2026-06-17-treasure-hunt-skeleton-and-tap-slice.md` |
| 開発手順（セットアップ・実行・テスト・配布） | [`docs/development.md`](docs/development.md) |
| AI 駆動開発の運用指針 | `CLAUDE.md` |

> 一次根拠（Deep Research レポート, 2026-06-17）:
> `ai-research-pipeline/.../reports/flutter-kids-2d-educational-apps-2026.md`（技術）と
> `.../kids-treasure-hunt-game-design-and-features-2026.md`（ゲームデザイン）。

---

## 1. コンセプト

未就学〜低学年（5〜11 歳）向けの、読み書き不要で遊べる宝探し。ホーム画面を「宝の地図」に
見立て、各シーンをステージとして配置する。

**コアループ**: 探す → タップで見つける → ジューシーに祝う（拡大 + キラッ + 音）→
図鑑に収納 → コンプリート → 次のエリア解放。

**ゲーム設計原則**（調査レポート由来）
- 失敗を罰しない（空振りに ×・減点・不快音を出さない）
- 時間制限なし・無制限ヒント
- 0〜5 歳は無報酬で成立（発見と図鑑充填そのものが報酬。スター/競争は入れない）
- 発見の瞬間に多感覚フィードバックを集中
- 読字に依存しない（絵 + 音 + アニメで誘導）

- **対象プラットフォーム**: Android タブレット / iPad（タブレット横向きを第一級でサポート）
- **対象年齢**: 5〜11 歳（難易度を年齢帯で切替）
- **言語**: 日本語 / 英語（ja/en）

### 将来の拡張候補（未実装）

MVP のコアを固めた後に足し算で重ねる。現時点では**実装していない**。

- **Dig（掘る/なでる）操作**: 覆い砂をスクラッチして宝を露出させる。シーク＆ファインドの
  コアループ上に `seek_find` feature の内部差し替えで追加できる。
- **ミニゲーム拡張**: 迷路 / 間違い探し / タイピング 等を「ミニゲームコレクション」として
  追加する構想（当初コンセプト）。
- ヒント自動強化（虫眼鏡/指さし）、複数ワールド、スター/カスタマイズ/実績（年齢帯で段階導入）。

---

## 2. 技術スタック（実装済み）

| 用途 | 採用 | 備考 |
|---|---|---|
| Flutter バージョン管理 | **fvm**（`.fvmrc` = Flutter 3.44.2） | ローカルも CI も同じ版。コマンドは `fvm flutter` / `fvm dart` |
| 描画・ゲーム実装 | **純 Flutter 標準 API** | `InteractiveViewer` + `GestureDetector.localPosition` + `Rect.contains`。ゲームループ/物理が不要なため **Flame は入れない** |
| 状態管理 | **Riverpod**（手動 `Notifier`/`FamilyNotifier`・コード生成なし） | 将来 `@riverpod` + build_runner へ移行可 |
| ルーティング | **go_router** | `/`・`/hunt/:sceneId`・`/settings` |
| 永続化 | **shared_preferences** | `lib/data/` の Repository で隠蔽（バックエンド無し） |
| 音声 | **audioplayers**（通信なし・効果音のみ） | 発見音 / 完了音 |
| ローカライズ | **ja/en の文字列 Map**（`lib/shared/strings/`） | 本格化時に `intl`/ARB へ移行可 |

> 「純 Flutter」原則: ゲームループや物理が要らない限り Flame は入れない。多数スプライトの
> 常時アニメ・物理・パーティクルが必要になった段階でのみ `seek_find` の内部実装として検討する。

### 入れない SDK（Kids 規制のため厳守）

```
絶対に入れない:
  Firebase Analytics / Crashlytics  … Apple Kids Category は「コード削除」が必要（disable 不可）
  AdMob 行動広告 / AppsFlyer / Adjust / Facebook SDK … COPPA・Families 違反
  Google Maps 等の位置情報              … Families 禁止
設計原則: 行動広告 SDK ゼロ・データ収集ゼロ・保護者ゲートを MVP に含める
```

> **Firebase App Distribution（配布ツール）は可**: CI からビルドをアップロードするだけで、
> `firebase_app_distribution` 等の**ランタイム SDK はアプリに埋め込まない**（→ §8）。

---

## 3. クイックスタート

詳細は [`docs/development.md`](docs/development.md)。

```bash
dart pub global activate fvm   # 未導入の場合
fvm install                    # .fvmrc の Flutter 3.44.2 を取得
fvm flutter pub get
fvm flutter run                # 接続済みの実機/エミュレータで起動
bash scripts/check.sh          # format + analyze + test（fvm 経由）
```

---

## 4. プロジェクト構成

**単一アプリ内 feature 分割**（Melos monorepo は個人開発には過剰）。

```
lib/
  main.dart                       # SharedPreferences ロード + ProviderScope + 初期解放
  app.dart                        # MaterialApp.router + KidsTheme + locale
  router.dart                     # go_router: / , /hunt/:sceneId , /settings
  providers.dart                  # prefs/repos/audio/locale/found/scene の Provider 群
  scenes_catalog.dart             # ホームに並べるシーン一覧
  features/
    treasure_map/                 # ホーム = 宝の地図（解放/クリア表示）
    seek_find/                    # ★コア = 隠しオブジェクト探し（Tap 版）
      seek_find_screen.dart       #   InteractiveViewer + 図鑑 + 完了
      seek_find_logic.dart        #   findHitTargetId（純Dart・テスト対象）
      models/  widgets/
    settings/                     # 言語切替 + 保護者ゲート入口 stub
  data/                           # ProgressRepository / SettingsRepository（shared_preferences）
  shared/                         # audio / strings / theme / widgets
assets/
  scenes/scene01.json             # シーン定義（隠し宝の正規化 Rect）
  sfx/found.wav, complete.wav     # 効果音（現状はプレースホルダ無音）
test/  unit/  widget/             # 22 テスト（hit-test / repository / 画面 / 完了 など）
```

---

## 5. 子供向け UX チェックリスト（実装基準）

| 要件 | 基準 |
|---|---|
| タッチターゲット | 最小 60×60 dp（`KidsButton` で担保） |
| 失敗を罰しない | 空振り・誤タップに ×/減点/不快音を出さない |
| 誤タップ防止 | 重要操作間 0.5s 以上（`IgnorePointer` + `Future.delayed`） |
| 非テキスト UI | アイコン + 音声ナビ（`Semantics` + 音声） |
| 音声フィードバック | 正解=明るい音 / 完了=ジングル |
| 達成演出 | クリアで星・キャラがジャンプ（`AnimationController`） |
| 色覚対応 | 赤/緑のみに依存しない（形 + パターン併用） |
| コントラスト | WCAG AA 4.5:1 以上 |
| 保護者ゲート | 設定・課金・外部リンク前に算数問題ダイアログ必須（MVP は入口 stub） |
| タブレット横向き | 2 カラム（`LayoutBuilder` / `OrientationBuilder`） |

---

## 6. 規制対応（最重要リスク・2026）

> **免責**: 以下はレポート（2026-06-17 時点の公式一次情報の解釈）に基づく開発方針であり
> 法的助言ではない。**リリース前に弁護士等へ最終確認する**。

同時に満たすべき 3 セット:

| 規制 | 開発側の対応 |
|---|---|
| **COPPA / 2026 改正**（2026-04-22 発効） | データ収集ゼロ設計。第三者共有なし。Firebase Analytics 除外 |
| **Apple Kids Category** | 保護者ゲート必須。第三者 analytics の **コード削除**（disable では不可）。Privacy Nutrition Labels = No Data Collected |
| **Google Play Families** | Self-Certified Ads SDK のみ（本アプリは広告なし）。位置情報なし。Console で対象年齢を正確に申告 |

**3 原則**: ①行動広告 SDK を一切入れない ②データ収集ゼロ設計 ③保護者ゲートを MVP に含める。

---

## 7. マネタイズ方針（kids-safe）

1. まず **完全買い切り**（¥120–¥360）でリリース。Kids Category で問題が少なく最もシンプル。
2. 反応を見て **保護者ゲート付き IAP**（追加ステージパック ¥99–¥250）を追加。
3. **行動広告は絶対に入れない**。

IAP は必ず「保護者ゲート（算数問題）→ `in_app_purchase`」の順で起動する。

---

## 8. テスト・CI・配布

- **テスト**（`fvm flutter test`, 計 22）
  - Unit: `findHitTargetId`（座標正規化 + `Rect.contains`）/ `ProgressRepository` / `SettingsRepository` / locale / strings
  - Widget: 宝の地図ホーム / シーン画面（タップ発見 → 図鑑充填 → コンプリート / 再入リセット）/ `KidsButton` / `CollectionBar` / `FoundBurst` / 起動スモーク
  - Golden（alchemist）は画面が安定してから導入（現スコープ外）
- **ローカル品質チェック**: `scripts/check.sh`（`fvm dart format --set-exit-if-changed` → `fvm flutter analyze` → `fvm flutter test`）
- **CI（GitHub Actions / `workflow_dispatch`）**: Firebase App Distribution への **Android APK 手動配布のみ**。
  `flutter-version-file: .fvmrc` でローカルと同じ版。詳細・必要 Secrets は [`docs/development.md`](docs/development.md)。

---

## 9. AI 駆動開発（Claude Code）

- `.claude/` に①汎用（開発フロー/レビュー）と②Dart/Flutter 特化（`rules/dart`, `dart-flutter-patterns`,
  `flutter-reviewer` 等）のリソースを配置。運用指針は `CLAUDE.md`。
- 公式タスク指向スキル（任意・vendoring せず導入）:
  ```bash
  npx skills add flutter/skills  --skill '*' --agent universal
  npx skills add dart-lang/skills --skill '*' --agent universal
  ```
- Dart MCP Server: `claude mcp add --transport stdio dart -- dart mcp-server`
- GitHub Issues → `/loop` で自走 → `scripts/check.sh` → `/create-pr` → `/merge-pr`。

---

## 10. ロードマップ

- [x] **MVP**: 基盤スケルトン + シーク＆ファインド（Tap 版 1 シーン）コアループ ✅
- [x] fvm でバージョン統一（Flutter 3.44.2） / Android Firebase App Distribution ワークフロー
- [ ] 実機（Android タブレット / iPad）での DoD 手動確認
- [ ] 実シーンのイラスト + お題アセット差し替え（現状はグラデーション + 無音のプレースホルダ）
- [ ] **Dig（掘る）操作**の追加（同コアループ上に内部差し替え）
- [ ] ヒント自動強化 / 複数ワールド / 保護者ゲート本体（算数問題）
- [ ] iOS 配布、Golden テスト、Families / Kids Category 申請

---

## ライセンス / アセット方針

- 効果音・画像は CC0 / CC BY（freesound.org, opengameart.org, Pixabay）を使用し、帰属が必要な
  ものは `CREDITS.md` に明記する。
- フォント: 日本語 = M PLUS Rounded 1c、英字 = Fredoka One / Nunito（Google Fonts）。

---

_本 README は実装の進行に合わせて更新する。現行の詳細設計は `docs/superpowers/` を正典とする。_
