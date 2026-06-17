---
name: codebase-onboarding
description: Analyze an unfamiliar codebase and generate a structured onboarding guide with architecture map, key entry points, conventions, and a starter CLAUDE.md. Use when joining a new project or setting up Claude Code for the first time in a repo.
origin: ECC
---

# Codebase Onboarding

不慣れなコードベースを体系的に分析し、構造化されたオンボーディングガイドを生成します。新しいプロジェクトに参加する開発者や、既存のリポジトリで初めて Claude Code をセットアップする場合に設計されています。

## 使用タイミング

- プロジェクトで初めて Claude Code を開く場合
- 新しいチームやリポジトリに参加する場合
- ユーザーが「このコードベースを理解する手助けをして」と依頼した場合
- ユーザーがプロジェクト用の CLAUDE.md の生成を依頼した場合
- ユーザーが「オンボーディングして」「このリポジトリを案内して」と言った場合

## 仕組み

### フェーズ 1: Reconnaissance

すべてのファイルを読まずに、プロジェクトに関する生のシグナルを収集します。以下のチェックを並列で実行します：

```
1. パッケージマニフェストの検出
   → package.json, go.mod, Cargo.toml, pyproject.toml, pom.xml, build.gradle,
     Gemfile, composer.json, mix.exs, pubspec.yaml

2. フレームワークのフィンガープリンティング
   → next.config.*, nuxt.config.*, angular.json, vite.config.*,
     django settings, flask app factory, fastapi main, rails config

3. エントリポイントの特定
   → main.*, index.*, app.*, server.*, cmd/, src/main/

4. ディレクトリ構造のスナップショット
   → ディレクトリツリーの上位2階層（node_modules, vendor,
     .git, dist, build, __pycache__, .next は除外）

5. 設定・ツールの検出
   → .eslintrc*, .prettierrc*, tsconfig.json, Makefile, Dockerfile,
     docker-compose*, .github/workflows/, .env.example, CI 設定

6. テスト構造の検出
   → tests/, test/, __tests__/, *_test.go, *.spec.ts, *.test.js,
     pytest.ini, jest.config.*, vitest.config.*
```

### フェーズ 2: Architecture Mapping

偵察データから以下を特定します：

**技術スタック**
- 言語とバージョン制約
- フレームワークと主要ライブラリ
- データベースと ORM
- ビルドツールとバンドラー
- CI/CD プラットフォーム

**アーキテクチャパターン**
- モノリス、モノレポ、マイクロサービス、またはサーバーレス
- フロントエンド/バックエンド分離またはフルスタック
- API スタイル：REST、GraphQL、gRPC、tRPC

**主要ディレクトリ**
トップレベルのディレクトリをその目的にマッピングします：

<!-- Example for a React project — replace with detected directories -->
```
src/components/  → React UI コンポーネント
src/api/         → API ルートハンドラ
src/lib/         → 共有ユーティリティ
src/db/          → データベースモデルとマイグレーション
tests/           → テストスイート
scripts/         → ビルド・デプロイスクリプト
```

**データフロー**
1つのリクエストをエントリからレスポンスまで追跡します：
- リクエストはどこから入るか？（ルーター、ハンドラ、コントローラー）
- どのように検証されるか？（ミドルウェア、スキーマ、ガード）
- ビジネスロジックはどこにあるか？（サービス、モデル、ユースケース）
- データベースにどのように到達するか？（ORM、生クエリ、リポジトリ）

### フェーズ 3: Convention Detection

コードベースが既に従っているパターンを特定します：

**命名規則**
- ファイル命名：kebab-case、camelCase、PascalCase、snake_case
- コンポーネント/クラスの命名パターン
- テストファイルの命名：`*.test.ts`、`*.spec.ts`、`*_test.go`

**コードパターン**
- エラーハンドリングスタイル：try/catch、Result 型、エラーコード
- 依存性注入またはダイレクトインポート
- 状態管理アプローチ
- 非同期パターン：コールバック、Promise、async/await、チャネル

**Git 規約**
- 最近のブランチからのブランチ命名
- 最近のコミットからのコミットメッセージスタイル
- PR ワークフロー（squash、merge、rebase）
- リポジトリにコミットがない場合や浅い履歴のみの場合（例：`git clone --depth 1`）、このセクションをスキップし「Git 履歴が利用不可または規約検出には浅すぎます」と記載

### フェーズ 4: Generate Onboarding Artifacts

2つの成果物を生成します：

#### 出力 1: Onboarding Guide

```markdown
# Onboarding Guide: [Project Name]

## Overview
[2-3文：このプロジェクトが何をするか、誰に役立つか]

## Tech Stack
<!-- Example for a Next.js project — replace with detected stack -->
| レイヤー | テクノロジー | バージョン |
|-------|-----------|---------|
| Language | TypeScript | 5.x |
| Framework | Next.js | 14.x |
| Database | PostgreSQL | 16 |
| ORM | Prisma | 5.x |
| Testing | Jest + Playwright | - |

## Architecture
[コンポーネントがどのように接続するかの図または説明]

## Key Entry Points
<!-- Example for a Next.js project — replace with detected paths -->
- **API routes**: `src/app/api/` — Next.js ルートハンドラ
- **UI pages**: `src/app/(dashboard)/` — 認証済みページ
- **Database**: `prisma/schema.prisma` — データモデルの信頼できる情報源
- **Config**: `next.config.ts` — ビルドおよびランタイム設定

## Directory Map
[トップレベルディレクトリ → 目的のマッピング]

## Request Lifecycle
[1つの API リクエストをエントリからレスポンスまで追跡]

## Conventions
- [ファイル命名パターン]
- [エラーハンドリングアプローチ]
- [テストパターン]
- [Git ワークフロー]

## Common Tasks
<!-- Example for a Node.js project — replace with detected commands -->
- **開発サーバー起動**: `npm run dev`
- **テスト実行**: `npm test`
- **リンター実行**: `npm run lint`
- **データベースマイグレーション**: `npx prisma migrate dev`
- **本番ビルド**: `npm run build`

## Where to Look
<!-- Example for a Next.js project — replace with detected paths -->
| やりたいこと | 参照場所 |
|--------------|-----------|
| API エンドポイントを追加 | `src/app/api/` |
| UI ページを追加 | `src/app/(dashboard)/` |
| データベーステーブルを追加 | `prisma/schema.prisma` |
| テストを追加 | ソースパスに対応する `tests/` |
| ビルド設定を変更 | `next.config.ts` |
```

#### 出力 2: Starter CLAUDE.md

検出された規約に基づいて、プロジェクト固有の CLAUDE.md を生成または更新します。`CLAUDE.md` が既に存在する場合は、まずそれを読み込んで強化します。既存のプロジェクト固有の指示を保持し、追加・変更された内容を明確に示します。

```markdown
# Project Instructions

## Tech Stack
[検出されたスタックのサマリー]

## Code Style
- [検出された命名規則]
- [検出された従うべきパターン]

## Testing
- テスト実行: `[検出されたテストコマンド]`
- テストパターン: [検出されたテストファイル規約]
- カバレッジ: [設定されている場合、カバレッジコマンド]

## Build & Run
- Dev: `[検出された開発コマンド]`
- Build: `[検出されたビルドコマンド]`
- Lint: `[検出されたリントコマンド]`

## Project Structure
[主要ディレクトリ → 目的のマップ]

## Conventions
- [検出可能な場合のコミットスタイル]
- [検出可能な場合の PR ワークフロー]
- [エラーハンドリングパターン]
```

## ベストプラクティス

1. **すべてを読まない** — 偵察では Read ではなく Glob と Grep を使用してください。あいまいなシグナルに対してのみ選択的に Read を使用します。
2. **推測ではなく検証** — 設定からフレームワークが検出されたが実際のコードが異なるものを使用している場合、コードを信頼してください。
3. **既存の CLAUDE.md を尊重** — 既に存在する場合は、置き換えるのではなく強化してください。新規と既存の内容を明示してください。
4. **簡潔に保つ** — オンボーディングガイドは2分で読み取れるものにしてください。詳細はコードに含め、ガイドには含めないでください。
5. **不明点はフラグを立てる** — 規約を自信を持って検出できない場合、推測するよりも明示してください。「テストランナーを特定できませんでした」は、誤った回答よりも優れています。

## 避けるべきアンチパターン

- 100行を超える CLAUDE.md の生成 — 焦点を絞ってください
- すべての依存関係のリスト化 — コードの書き方に影響するもののみをハイライトしてください
- 明白なディレクトリ名の説明 — `src/` には説明は不要です
- README のコピー — オンボーディングガイドは README にない構造的な洞察を追加します

## 例

### 例 1: 新しいリポジトリでの初回
**ユーザー**: 「このコードベースにオンボーディングして」
**アクション**: フルの4フェーズワークフローを実行 → Onboarding Guide + Starter CLAUDE.md を生成
**出力**: Onboarding Guide を会話に直接表示し、`CLAUDE.md` をプロジェクトルートに書き込み

### 例 2: 既存プロジェクト用の CLAUDE.md 生成
**ユーザー**: 「このプロジェクト用の CLAUDE.md を生成して」
**アクション**: フェーズ 1-3 を実行、Onboarding Guide をスキップ、CLAUDE.md のみ生成
**出力**: 検出された規約を含むプロジェクト固有の `CLAUDE.md`

### 例 3: 既存の CLAUDE.md の強化
**ユーザー**: 「現在のプロジェクト規約で CLAUDE.md を更新して」
**アクション**: 既存の CLAUDE.md を読み込み、フェーズ 1-3 を実行、新しい発見をマージ
**出力**: 追加内容が明確にマークされた更新済み `CLAUDE.md`
