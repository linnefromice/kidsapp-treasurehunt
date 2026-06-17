---
name: security-scan
description: Scan your Claude Code configuration (.claude/ directory) for security vulnerabilities, misconfigurations, and injection risks using AgentShield. Checks CLAUDE.md, settings.json, MCP servers, hooks, and agent definitions.
origin: ECC
---

# Security Scan Skill

[AgentShield](https://github.com/affaan-m/agentshield) を使用して Claude Code の設定をセキュリティ問題について監査します。

## 起動条件

- 新しい Claude Code プロジェクトのセットアップ時
- `.claude/settings.json`、`CLAUDE.md`、または MCP 設定の変更後
- 設定変更をコミットする前
- 既存の Claude Code 設定がある新しいリポジトリへのオンボーディング時
- 定期的なセキュリティ衛生チェック

## スキャン対象

| ファイル | チェック内容 |
|---------|------------|
| `CLAUDE.md` | ハードコードされたシークレット、自動実行命令、プロンプトインジェクションパターン |
| `settings.json` | 過度に許容的な許可リスト、欠落した拒否リスト、危険なバイパスフラグ |
| `mcp.json` | リスクのある MCP サーバー、ハードコードされた環境変数シークレット、npx サプライチェーンリスク |
| `hooks/` | 補間によるコマンドインジェクション、データ流出、サイレントエラー抑制 |
| `agents/*.md` | 無制限のツールアクセス、プロンプトインジェクションの攻撃面、欠落したモデル仕様 |

## 前提条件

AgentShield がインストールされている必要があります。確認して必要に応じてインストールしてください:

```bash
# インストール確認
npx ecc-agentshield --version

# グローバルインストール（推奨）
npm install -g ecc-agentshield

# または npx で直接実行（インストール不要）
npx ecc-agentshield scan .
```

## 使い方

### 基本スキャン

現在のプロジェクトの `.claude/` ディレクトリに対して実行します:

```bash
# 現在のプロジェクトをスキャン
npx ecc-agentshield scan

# 特定のパスをスキャン
npx ecc-agentshield scan --path /path/to/.claude

# 最小重要度フィルター付きでスキャン
npx ecc-agentshield scan --min-severity medium
```

### 出力フォーマット

```bash
# ターミナル出力（デフォルト） — カラーレポートとグレード
npx ecc-agentshield scan

# JSON — CI/CD 統合用
npx ecc-agentshield scan --format json

# Markdown — ドキュメント用
npx ecc-agentshield scan --format markdown

# HTML — 自己完結型ダークテーマレポート
npx ecc-agentshield scan --format html > security-report.html
```

### 自動修正

安全な修正を自動的に適用します（自動修正可能とマークされたもののみ）:

```bash
npx ecc-agentshield scan --fix
```

以下を行います:
- ハードコードされたシークレットを環境変数参照に置き換え
- ワイルドカード権限をスコープ付きの代替手段に制限
- 手動のみの提案は変更しない

### Opus 4.6 詳細分析

より深い分析のために敵対的3エージェントパイプラインを実行します:

```bash
# ANTHROPIC_API_KEY が必要
export ANTHROPIC_API_KEY=your-key
npx ecc-agentshield scan --opus --stream
```

以下を実行します:
1. **Attacker (Red Team)** — 攻撃ベクトルを発見
2. **Defender (Blue Team)** — 強化を推奨
3. **Auditor (Final Verdict)** — 両方の視点を総合

### セキュア設定の初期化

ゼロから安全な `.claude/` 設定をスキャフォールドします:

```bash
npx ecc-agentshield init
```

以下を作成します:
- スコープ付き権限と拒否リストを持つ `settings.json`
- セキュリティベストプラクティスを含む `CLAUDE.md`
- `mcp.json` プレースホルダー

### GitHub Action

CI パイプラインに追加します:

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: '.'
    min-severity: 'medium'
    fail-on-findings: true
```

## 重要度レベル

| グレード | スコア | 意味 |
|---------|-------|------|
| A | 90-100 | セキュアな設定 |
| B | 75-89 | 軽微な問題 |
| C | 60-74 | 注意が必要 |
| D | 40-59 | 重大なリスク |
| F | 0-39 | クリティカルな脆弱性 |

## 結果の解釈

### クリティカルな発見（即座に修正）
- 設定ファイル内のハードコードされた API キーやトークン
- 許可リスト内の `Bash(*)`（無制限のシェルアクセス）
- `${file}` 補間によるフック内のコマンドインジェクション
- シェル実行 MCP サーバー

### 高い発見（本番環境前に修正）
- CLAUDE.md 内の自動実行命令（プロンプトインジェクションベクトル）
- 権限設定における拒否リストの欠落
- 不要な Bash アクセスを持つエージェント

### 中程度の発見（推奨）
- フック内のサイレントエラー抑制（`2>/dev/null`、`|| true`）
- PreToolUse セキュリティフックの欠落
- MCP サーバー設定における `npx -y` 自動インストール

### 情報の発見（認知）
- MCP サーバーの説明の欠落
- 良い実践として正しくフラグ付けされた禁止命令

## リンク

- **GitHub**: [github.com/affaan-m/agentshield](https://github.com/affaan-m/agentshield)
- **npm**: [npmjs.com/package/ecc-agentshield](https://www.npmjs.com/package/ecc-agentshield)
