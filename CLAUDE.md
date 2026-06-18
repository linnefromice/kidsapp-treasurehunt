# kidsapp-treasurehunt

子供向け **2D 宝探しアプリ**（シーク＆ファインド = 隠しオブジェクト探し）。Android タブレット /
iPad 向けに **Flutter** で個人開発する。

> **設計の正典（参照順）**
> 1. **現行のゲーム/実装設計** = `docs/superpowers/specs/2026-06-17-treasure-hunt-skeleton-design.md`
>    と `docs/superpowers/plans/2026-06-17-treasure-hunt-skeleton-and-tap-slice.md`。
>    **MVP のコアは「シーク＆ファインド（タップで探す）」。迷路ではない。**
> 2. **規制・子供向け UX 基準・アセット方針の一次情報** = [README.md](./README.md)。
>    （README の当初コンセプトは「迷路/間違い探し/タイピングのミニゲーム集」だが、MVP の
>    ゲーム構成は上記 spec が上書きする。規制・UX・ライセンス方針は README が引き続き有効。）

---

## プロジェクト概要

| 項目 | 内容 |
|------|------|
| コアゲーム | **シーク＆ファインド**：1 枚のシーンをピンチ拡大/パンしながら隠し宝をタップ → 図鑑に収納 → 全部見つけてコンプリート → 次シーン解放 |
| 操作 | **タップで探す（Tap 版から開始）**。「掘る (Dig / スクラッチ)」は同じコアループ上に後続で内部差し替え |
| 対象 | Android タブレット・iPad（タブレット横向きが第一級） / 5〜11 歳 / 言語 ja・en |
| セーブ | **固定 3 スロット**・進捗のみ独立（言語は共通）。起動時にアバターで選択。リセットは保護者ゲート経由 |
| バックエンド | **無し**（端末ローカル完結） |

## ゲーム設計原則（調査レポート由来 / spec §1.3）

- **失敗を罰しない**（空振りに ×・減点・不快音を出さない）
- **時間制限なし**・**無制限ヒント**
- **0–5 は無報酬で成立**（発見と図鑑充填そのものが報酬。スター/競争/リーダーボードは入れない）
- 発見の瞬間に**多感覚フィードバックを集中**（拡大 + キラッ + 音）
- 読字に依存しない（絵 + 音 + アニメで誘導）

## Flutter バージョン（fvm で統一）

- **`.fvmrc` が唯一の真実の源**（現在 `Flutter 3.44.2` / Dart 3.12.2）。ローカルも CI も同じ版を使う。
- ローカルは必ず **`fvm flutter ...` / `fvm dart ...`**（素の `flutter` を直接使わない）。初回: `fvm install`（`.fvmrc` の版を取得）。バージョン更新: `fvm use <version>` → 全テスト確認 → コミット。
- CI は `subosito/flutter-action` の `flutter-version-file: .fvmrc` で同じ版を読む。
- `.fvm/`（SDK シンボリックリンク実体）は gitignore、`.fvmrc` はコミット。

## 技術スタック

- **コア = 純 Flutter 標準 API**：`InteractiveViewer`（ズーム/パン）+ シーン子要素上の
  `GestureDetector` の `localPosition`（= シーン座標）+ `Rect.contains`（正規化 Rect で当たり判定）。
  ゲームループ・物理が不要なため **Flame は入れない**。
- 状態管理: **Riverpod**（MVP は手動 `Notifier`/`Provider`・**コード生成なし**。将来 `@riverpod` へ移行可）
- ルーティング: **go_router**（`routerProvider`）。ルート: `/slots`(初期) / `/` / `/hunt/:sceneId` / `/settings`。アクティブスロット未選択なら `/slots` に redirect。音声: **audioplayers**（通信なし・効果音のみ）
- 永続化: **shared_preferences**（`lib/data/` の Repository で隠蔽）。進捗はセーブスロットで名前空間化（`progress.<slotId>.*`）、`progressRepositoryProvider` は `activeSlotProvider` にスコープ。将来 DB へ差し替えても上位不変
- i18n: 当面 **ja/en の文字列 Map**（`lib/shared/strings/`）。本格化時に `intl`/ARB へ移行可
- 構成: `lib/features/{save_slots, treasure_map, seek_find, settings}` + `lib/data` + `lib/shared`（+ `lib/scenes_catalog.dart` / `lib/save_slots_catalog.dart`）

## 絶対制約（Kids 規制・最重要 / README §6）

> リリース前に弁護士等へ最終確認すること（法的助言ではない）。

```
絶対に入れない SDK:
  Firebase Analytics / Crashlytics   … Apple Kids Category は「コード削除」必須（disable 不可）
  AdMob 行動広告 / AppsFlyer / Adjust / Facebook SDK … COPPA・Families 違反
  位置情報（Google Maps 等）           … Families 禁止
3 原則: ①行動広告 SDK ゼロ ②データ収集ゼロ設計 ③保護者ゲートを MVP に含める
```

- AI はライブラリ・SDK を提案する際、必ずこの制約に照らして判断する。違反する依存は提案しない。
- **Firebase App Distribution（配布ツール）は可**：CI からビルドをアップロードするだけで、
  `firebase_app_distribution` 等の**ランタイム SDK はリリースビルドに埋め込まない**。

## 子供向け UX 基準（README §5 + 調査レポート）

タッチターゲット最小 60×60 dp / 重要操作間 0.5s 以上 / 失敗を罰しない・急かさない /
色は赤緑のみに依存しない / コントラスト WCAG AA 4.5:1 以上 /
設定・課金・外部リンク前に保護者ゲート（算数問題）必須 / タブレット横向きは 2 カラム。

## テスト戦略（spec §8）

- **Unit**: `findHitTargetId`（座標正規化 + `Rect.contains`）/ `ProgressRepository`（slotスコープ・独立性・`clearAll`） /
  `SettingsRepository` / `SaveSlotRepository` / `SaveSlotController`（生成/リセット・スロット独立）（`SharedPreferences.setMockInitialValues` を使用）
- **Widget**: スロット選択（新規→遷移 / リセット→保護者ゲート）/ 宝の地図ホーム / シーン画面（タップ発見 → 図鑑充填 → コンプリート）/ `KidsButton` / 起動スモーク（`/slots`）
- Golden（alchemist）は画面が安定してから導入（現スコープ外）
- **ローカル品質チェック**: `scripts/check.sh` = `fvm dart format --set-exit-if-changed .` →
  `fvm flutter analyze` → `fvm flutter test`

## ビルド / 配布

- **CI（GitHub Actions / `workflow_dispatch`）= Firebase App Distribution への Android APK 手動配布のみ**。
  - `g-runner-flutter` 方式を踏襲: `actions/setup-java@v4`(temurin 17) → flutter-action → `flutter build apk --release` → `wzieba/Firebase-Distribution-Github-Action`。
  - release は `android/app/build.gradle.kts` の既定で **debug 鍵署名**（専用 keystore 不要。App Distribution のテスター配布はこれで可）。
  - 必要 Secrets: `FIREBASE_APP_ID` / `FIREBASE_SERVICE_ACCOUNT_KEY`（App Distribution Admin 権限のサービスアカウント JSON 全文）。テスターグループ名は `internal-testers`。
  - 自動配布したい場合は `distribute.yml` の `push: branches: [main]` のコメントを外す。
- lint / format / test は当面**ローカル**（`scripts/check.sh`）。後で同スクリプトを CI ジョブへ昇格可能。
- iOS 配布は当面スコープ外（Apple 署名の CI 投入が重いため。ローカル Xcode で確認）。

---

## Claude Code 運用

### 配置済みリソース（`.claude/`）

リソースは2系統。①汎用（開発フロー・基盤）= `claude-code-workspace` 由来。
②Dart/Flutter 特化 = `affaan-m/ECC` 由来。**Dart 特化は `common` を拡張**する関係。

| 種別 | 汎用（common） | Dart/Flutter 特化（ECC 由来） |
|------|------|------|
| ルール | `.claude/rules/common/`（規約・テスト・git・レビュー・セキュリティ） | `.claude/rules/dart/`（`coding-style`/`patterns`/`testing`/`security`/`hooks`、`**/*.dart` 等に path-scoped） |
| スキル | tdd-workflow, coding-standards, hexagonal-architecture, adapt-external-docs 等 | **dart-flutter-patterns**（Riverpod/GoRouter/sealed/async/widget 設計）、**flutter-dart-code-review**（レビュー観点集） |
| コマンド | `/create-pr` `/merge-pr` 他 | `/flutter-build`（analyze 修正）`/flutter-test`（テスト実行・修正）`/flutter-review`（Flutter レビュー） |
| エージェント | code-reviewer / architect 等 | **flutter-reviewer**（Flutter/Dart レビュー）、**dart-build-resolver**（analyze/build/pub/build_runner 修復） |

> Dart コードの編集・レビュー・ビルド修復の前には、対応する `rules/dart/` と上記スキルを参照する。
> （TypeScript 用リソースは Dart プロジェクトのため除外済み。）

### 外部リソース

- Dart MCP Server: `claude mcp add --transport stdio dart -- dart mcp-server`
- **公式タスク指向スキル**（Google 管理・ドリフト回避のため vendoring せず install で導入）:
  ```
  npx skills add flutter/skills   --skill '*' --agent universal   # github.com/flutter/skills
  npx skills add dart-lang/skills  --skill '*' --agent universal   # github.com/dart-lang/skills
  ```
  本プロジェクトに特に有用: `flutter-build-responsive-layout`（タブレット/iPad 第一級対応）、
  `flutter-setup-localization`（ja/en）、`dart-collect-coverage`（LCOV）、`flutter-add-integration-test`、
  `dart-use-pattern-matching`。
- 一次根拠の Deep Research レポートを取り込む際は `adapt-external-docs` スキルを使う。

### ワークフロー

#### 要求受付→実装フロー（一気通貫）

要求を受けたら以下の 3 ステップを **止まらずに** 実行する。

**[1] Spec 起草**
- 推奨設定を含む spec を書き切る（設計上の判断はまず自分で推奨案を決定）
- 聞くべき不確定ポイントはいったんストックしておく

**[2] 質問の整理**
- 推奨設定がある問いは自動採用（ユーザーに確認しない）
- 推奨設定に優劣がつかない問いのみ、**まとめて 1 回**質問してユーザーに判断を仰ぐ

**[3] Subagent-Driven Development → PR → セルフレビュー → セルフマージ**
- `superpowers:subagent-driven-development` スキルで実装（タスクごとに fresh subagent）
- 実装完了後: `scripts/check.sh` → `/create-pr` でブランチ作成 & PR 作成
- `flutter-reviewer` / `code-reviewer` エージェントでセルフレビュー → 指摘修正
- `/merge-pr` でマージ（squash or merge commit はプロジェクト慣習に従う）
- ユーザーを待たずに **一気通貫**で完走することが原則

> **例外**: アーキテクチャ変更・破壊的変更・外部公開 API の変更は、spec を提示して
> ユーザー承認を得てから [3] に進む。

#### 旧フロー（参考）
GitHub Issues でタスク分割 → Issue ごとに Claude Code を自走（`/loop`）→ ローカルで
`scripts/check.sh` → `/create-pr` → `/merge-pr`。実装は spec/plan を起点に TDD で進める。

---

## User Customization

If a `CLAUDE.local.md` file exists in the root directory, read it and **prioritize its
instructions over this file**. This allows individual developers to customize AI behavior
without affecting team-shared rules.

Example use cases for `CLAUDE.local.md`:
- Personal coding style preferences
- Local environment-specific configurations
- Custom workflow instructions
- Development focus areas
