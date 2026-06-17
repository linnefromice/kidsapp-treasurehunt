---
name: blueprint
description: >-
  Turn a one-line objective into a step-by-step construction plan for
  multi-session, multi-agent engineering projects. Each step has a
  self-contained context brief so a fresh agent can execute it cold.
  Includes adversarial review gate, dependency graph, parallel step
  detection, anti-pattern catalog, and plan mutation protocol.
  TRIGGER when: user requests a plan, blueprint, or roadmap for a
  complex multi-PR task, or describes work that needs multiple sessions.
  DO NOT TRIGGER when: task is completable in a single PR or fewer
  than 3 tool calls, or user says "just do it".
origin: community
---

# Blueprint — Construction Plan Generator

1行の目標を、任意のコーディングエージェントがコールドスタートで実行できるステップバイステップの構築計画に変換します。

## 使用タイミング

- 大規模な機能を、明確な依存関係順序を持つ複数の PR に分割する場合
- 複数セッションにまたがるリファクタリングやマイグレーションを計画する場合
- サブエージェント間で並行ワークストリームを調整する場合
- セッション間のコンテキスト喪失が手戻りを引き起こす可能性があるタスク

**使用しない場合**: 単一の PR で完了するタスク、3回未満のツール呼び出しで完了するタスク、またはユーザーが「とにかくやって」と言った場合。

## 仕組み

Blueprint は5フェーズのパイプラインを実行します：

1. **Research** — 事前チェック（git、gh auth、リモート、デフォルトブランチ）を行い、プロジェクト構造、既存の計画、メモリファイルを読み込んでコンテキストを収集します。
2. **Design** — 目標を1PR サイズのステップ（通常3〜12個）に分割します。各ステップに依存関係のエッジ、並列/直列の順序、モデルティア（最強 vs デフォルト）、ロールバック戦略を割り当てます。
3. **Draft** — `plans/` に自己完結型の Markdown プランファイルを作成します。各ステップにはコンテキストブリーフ、タスクリスト、検証コマンド、終了基準が含まれており、新しいエージェントが前のステップを読まなくても任意のステップを実行できます。
4. **Review** — 最強モデルのサブエージェント（例：Opus）にチェックリストとアンチパターンカタログに基づく敵対的レビューを委任します。最終化の前にすべての重大な問題を修正します。
5. **Register** — プランを保存し、メモリインデックスを更新し、ステップ数と並列処理のサマリーをユーザーに提示します。

Blueprint は git/gh の利用可否を自動検出します。git + GitHub CLI がある場合、完全なブランチ/PR/CI ワークフロープランを生成します。ない場合は、ダイレクトモード（ブランチなしでその場で編集）に切り替えます。

## 例

### 基本的な使い方

```
/blueprint myapp "migrate database to PostgreSQL"
```

`plans/myapp-migrate-database-to-postgresql.md` が以下のようなステップで生成されます：
- Step 1: PostgreSQL ドライバーと接続設定を追加
- Step 2: 各テーブルのマイグレーションスクリプトを作成
- Step 3: リポジトリレイヤーを新しいドライバーに更新
- Step 4: PostgreSQL に対する統合テストを追加
- Step 5: 古いデータベースコードと設定を削除

### マルチエージェントプロジェクト

```
/blueprint chatbot "extract LLM providers into a plugin system"
```

可能な箇所では並列ステップを含むプラン（例：プラグインインターフェースのステップ完了後に「Anthropic プラグインの実装」と「OpenAI プラグインの実装」を並列実行）、モデルティアの割り当て（インターフェース設計ステップには最強モデル、実装にはデフォルト）、各ステップ後に検証される不変条件（例：「既存のテストがすべてパスする」「コアにプロバイダーのインポートがない」）が生成されます。

## 主な機能

- **コールドスタート実行** — 各ステップには自己完結型のコンテキストブリーフが含まれます。事前のコンテキストは不要です。
- **敵対的レビューゲート** — すべてのプランは、完全性、依存関係の正確性、アンチパターン検出をカバーするチェックリストに基づいて、最強モデルのサブエージェントによるレビューを受けます。
- **ブランチ/PR/CI ワークフロー** — 各ステップに組み込まれています。git/gh がない場合はダイレクトモードに適切にフォールバックします。
- **並列ステップ検出** — 依存関係グラフにより、共有ファイルや出力依存関係のないステップを特定します。
- **プラン変更プロトコル** — ステップの分割、挿入、スキップ、順序変更、中止を正式なプロトコルと監査証跡付きで行えます。
- **実行時リスクゼロ** — 純粋な Markdown スキルです。リポジトリ全体が `.md` ファイルのみで構成されており、フック、シェルスクリプト、実行可能コード、`package.json`、ビルドステップはありません。インストールや呼び出し時に Claude Code のネイティブ Markdown スキルローダー以外は何も実行されません。

## インストール

このスキルは Everything Claude Code に同梱されています。ECC がインストールされている場合、別途インストールは不要です。

### ECC フルインストール

ECC リポジトリのチェックアウトから作業している場合、以下のコマンドでスキルの存在を確認してください：

```bash
test -f skills/blueprint/SKILL.md
```

後で更新する場合は、更新前に ECC の差分を確認してください：

```bash
cd /path/to/everything-claude-code
git fetch origin main
git log --oneline HEAD..origin/main       # 更新前に新しいコミットを確認
git checkout <reviewed-full-sha>          # レビュー済みの特定コミットにピン留め
```

### ベンダーによるスタンドアロンインストール

ECC のフルインストール外でこのスキルのみをベンダリングする場合、ECC リポジトリからレビュー済みのファイルを `~/.claude/skills/blueprint/SKILL.md` にコピーしてください。ベンダリングされたコピーには git リモートがないため、`git pull` ではなく、レビュー済みの ECC コミットからファイルを再コピーして更新してください。

## 要件

- Claude Code（`/blueprint` スラッシュコマンド用）
- Git + GitHub CLI（オプション — 完全なブランチ/PR/CI ワークフローを有効にします。Blueprint は不在を検出し、自動的にダイレクトモードに切り替えます）

## ソース

antbotlab/blueprint にインスパイアされています — アップストリームプロジェクトおよびリファレンスデザインです。
