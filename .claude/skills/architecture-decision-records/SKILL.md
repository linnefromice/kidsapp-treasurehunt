---
name: architecture-decision-records
description: Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alternatives considered, and rationale. Maintains an ADR log so future developers understand why the codebase is shaped the way it is.
origin: ECC
---

# Architecture Decision Records

コーディングセッション中に行われたアーキテクチャ上の決定を記録します。決定が Slack スレッド、PR コメント、誰かの記憶の中だけに存在するのではなく、このスキルはコードと共存する構造化された ADR ドキュメントを生成します。

## 起動条件

- ユーザーが明示的に「この決定を記録しよう」や「ADR にして」と言った場合
- ユーザーが重要な選択肢の間で選択する場合（フレームワーク、ライブラリ、パターン、データベース、API 設計）
- ユーザーが「X にすることにした...」や「Y ではなく X にする理由は...」と言った場合
- ユーザーが「なぜ X を選んだのか？」と質問した場合（既存の ADR を読む）
- アーキテクチャ上のトレードオフが議論される計画フェーズ中

## ADR Format

Michael Nygard が提唱した軽量 ADR フォーマットを、AI 支援開発向けに適応して使用します:

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [who was involved]

## Context

この決定や変更を動機付けている問題は何か？

[状況、制約、作用している力を説明する2-5文]

## Decision

提案している、または実行している変更は何か？

[決定を明確に述べる1-3文]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [利点]
- **Cons**: [欠点]
- **Why not**: [却下された具体的な理由]

### Alternative 2: [Name]
- **Pros**: [利点]
- **Cons**: [欠点]
- **Why not**: [却下された具体的な理由]

## Consequences

この変更により、何がやりやすくなり、何がやりにくくなるか？

### Positive
- [メリット 1]
- [メリット 2]

### Negative
- [トレードオフ 1]
- [トレードオフ 2]

### Risks
- [リスクと軽減策]
```

## ワークフロー

### 新しい ADR の記録

決定の瞬間が検出された場合:

1. **初期化（初回のみ）** — `docs/adr/` が存在しない場合、ディレクトリの作成、インデックステーブルヘッダーをシードした `README.md`（以下の ADR Index Format を参照）、手動使用のための空の `template.md` の作成についてユーザーに確認を求めます。明示的な同意なしにファイルを作成しないでください。
2. **決定の特定** — 行われている中心的なアーキテクチャ上の選択を抽出します
3. **コンテキストの収集** — 何がこの問題を引き起こしたか？どのような制約があるか？
4. **代替案の記録** — 他にどのような選択肢が検討されたか？なぜ却下されたか？
5. **結果の記述** — トレードオフは何か？何がやりやすく/やりにくくなるか？
6. **番号の割り当て** — `docs/adr/` の既存 ADR をスキャンしてインクリメント
7. **確認と書き込み** — ユーザーに ADR ドラフトを提示してレビューを依頼します。明示的な承認の後にのみ `docs/adr/NNNN-decision-title.md` に書き込みます。ユーザーが却下した場合、ファイルを書き込まずにドラフトを破棄します。
8. **インデックスの更新** — `docs/adr/README.md` に追記

### 既存 ADR の参照

ユーザーが「なぜ X を選んだのか？」と質問した場合:

1. `docs/adr/` が存在するか確認 — 存在しない場合は以下のように応答: 「このプロジェクトに ADR は見つかりませんでした。アーキテクチャ上の決定の記録を始めますか？」
2. 存在する場合、`docs/adr/README.md` のインデックスから関連するエントリをスキャン
3. 一致する ADR ファイルを読み取り、Context と Decision セクションを提示
4. 一致が見つからない場合は以下のように応答: 「その決定に関する ADR は見つかりませんでした。今から記録しますか？」

### ADR ディレクトリ構造

```
docs/
└── adr/
    ├── README.md              ← すべての ADR のインデックス
    ├── 0001-use-nextjs.md
    ├── 0002-postgres-over-mongo.md
    ├── 0003-rest-over-graphql.md
    └── template.md            ← 手動使用のための空テンプレート
```

### ADR Index Format

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-nextjs.md) | Use Next.js as frontend framework | accepted | 2026-01-15 |
| [0002](0002-postgres-over-mongo.md) | PostgreSQL over MongoDB for primary datastore | accepted | 2026-01-20 |
| [0003](0003-rest-over-graphql.md) | REST API over GraphQL | accepted | 2026-02-01 |
```

## 決定 Detection Signals

会話中にアーキテクチャ上の決定を示す以下のパターンに注目してください:

**明示的なシグナル**
- 「X にしよう」
- 「Y ではなく X を使うべき」
- 「このトレードオフは...の理由で価値がある」
- 「これを ADR として記録して」

**暗黙的なシグナル**（ADR の記録を提案 — ユーザーの確認なしに自動作成しない）
- 2つのフレームワークやライブラリを比較して結論に達する
- 根拠を述べたデータベーススキーマ設計の選択
- アーキテクチャパターンの選択（モノリス vs マイクロサービス、REST vs GraphQL）
- 認証/認可戦略の決定
- 代替案を評価した後のデプロイインフラの選択

## 良い ADR の条件

### Do
- **具体的に** — 「ORM を使う」ではなく「Prisma ORM を使う」
- **理由を記録** — 根拠は何であるかよりも重要
- **却下された代替案を含める** — 将来の開発者は何が検討されたかを知る必要がある
- **結果を正直に記述** — すべての決定にはトレードオフがある
- **短く保つ** — ADR は2分で読めるべき
- **現在形を使う** — 「X を使う予定」ではなく「X を使う」

### Don't
- 些細な決定を記録する — 変数の命名やフォーマットの選択に ADR は不要
- エッセイを書く — コンテキストセクションが10行を超えるなら長すぎ
- 代替案を省略する — 「ただ選んだ」は有効な根拠ではない
- マークせずに後付けする — 過去の決定を記録する場合は元の日付を記載
- ADR を放置する — 置き換えられた決定は後継を参照すべき

## ADR ライフサイクル

```
proposed → accepted → [deprecated | superseded by ADR-NNNN]
```

- **proposed**: 決定は議論中であり、まだ確定していない
- **accepted**: 決定は有効であり、従われている
- **deprecated**: 決定はもはや関連しない（例: 機能が削除された）
- **superseded**: より新しい ADR がこれを置き換えた（常に後継にリンク）

## 記録する価値のある決定のカテゴリ

| カテゴリ | 例 |
|----------|---------|
| **技術選択** | フレームワーク、言語、データベース、クラウドプロバイダー |
| **アーキテクチャパターン** | モノリス vs マイクロサービス、イベントドリブン、CQRS |
| **API 設計** | REST vs GraphQL、バージョニング戦略、認証メカニズム |
| **データモデリング** | スキーマ設計、正規化の決定、キャッシュ戦略 |
| **インフラストラクチャ** | デプロイモデル、CI/CD パイプライン、モニタリングスタック |
| **セキュリティ** | 認証戦略、暗号化アプローチ、シークレット管理 |
| **テスト** | テストフレームワーク、カバレッジ目標、E2E vs インテグレーションのバランス |
| **プロセス** | ブランチ戦略、レビュープロセス、リリースケイデンス |

## 統合 with Other Skills

- **Planner agent**: プランナーがアーキテクチャ変更を提案した場合、ADR の作成を提案します
- **Code reviewer agent**: 対応する ADR なしにアーキテクチャ変更を導入する PR をフラグします
