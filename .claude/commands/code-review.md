---
description: コードレビュー — ローカルの未コミット変更またはGitHub PR（PRモードにはPR番号/URLを渡す）
argument-hint: [pr-number | pr-url | ローカルレビューの場合は空欄]
---

# コードレビュー

> PRレビューモードはWirasmによるPRPs-agentic-engから適用。PRPワークフローシリーズの一部です。

**入力**: $ARGUMENTS

---

## モード選択

`$ARGUMENTS` にPR番号、PR URL、または `--pr` が含まれる場合:
→ 以下の **PRレビューモード** にジャンプ。

それ以外:
→ **ローカルレビューモード** を使用。

---

## ローカルレビューモード

未コミットの変更に対する包括的なセキュリティと品質レビュー。

### フェーズ 1 — 収集

```bash
git diff --name-only HEAD
```

変更ファイルがない場合は停止: 「レビューするものがありません。」

### フェーズ 2 — レビュー

各変更ファイルを完全に読みます。以下をチェック:

**セキュリティ問題（CRITICAL）:**
- ハードコードされた認証情報、APIキー、トークン
- SQLインジェクション脆弱性
- XSS脆弱性
- 入力バリデーションの欠落
- 安全でない依存関係
- パストラバーサルリスク

**コード品質（HIGH）:**
- 50行を超える関数
- 800行を超えるファイル
- 4レベルを超えるネスト深度
- エラーハンドリングの欠落
- console.log文
- TODO/FIXMEコメント
- パブリックAPIのJSDoc欠落

**ベストプラクティス（MEDIUM）:**
- ミューテーションパターン（代わりにイミュータブルを使用）
- コード/コメントでの絵文字使用
- 新しいコードのテスト欠落
- アクセシビリティの問題（a11y）

### フェーズ 3 — レポート

以下を含むレポートを生成:
- 重大度: CRITICAL、HIGH、MEDIUM、LOW
- ファイルの場所と行番号
- 問題の説明
- 推奨修正

CRITICALまたはHIGHの問題がある場合はコミットをブロック。
セキュリティ脆弱性のあるコードは決して承認しないでください。

---

## PRレビューモード

包括的なGitHub PRレビュー — diffを取得し、完全なファイルを読み、バリデーションを実行し、レビューを投稿します。

### フェーズ 1 — 取得

入力を解析してPRを決定:

| 入力 | アクション |
|------|----------|
| 番号（例: `42`） | PR番号として使用 |
| URL（`github.com/.../pull/42`） | PR番号を抽出 |
| ブランチ名 | `gh pr list --head <branch>` でPRを検索 |

```bash
gh pr view <NUMBER> --json number,title,body,author,baseRefName,headRefName,changedFiles,additions,deletions
gh pr diff <NUMBER>
```

PRが見つからない場合はエラーで停止。後続フェーズのためにPRメタデータを保存。

### フェーズ 2 — コンテキスト

レビューコンテキストを構築:

1. **プロジェクトルール** — `CLAUDE.md`、`.claude/docs/`、コントリビューティングガイドラインを読む
2. **PRPアーティファクト** — このPRに関連する実装コンテキストのために `.claude/PRPs/reports/` と `.claude/PRPs/plans/` を確認
3. **PRの意図** — PR説明から目標、リンクされたissue、テスト計画を解析
4. **変更ファイル** — すべての変更ファイルをリストし、タイプ別に分類（ソース、テスト、設定、ドキュメント）

### フェーズ 3 — レビュー

各変更ファイルを**完全に**読みます（diffハンクだけでなく、周囲のコンテキストが必要です）。

PRレビューでは、PRのheadリビジョンでの完全なファイル内容を取得:
```bash
gh pr diff <NUMBER> --name-only | while IFS= read -r file; do
  gh api "repos/{owner}/{repo}/contents/$file?ref=<head-branch>" --jq '.content' | base64 -d
done
```

7カテゴリにわたるレビューチェックリストを適用:

| カテゴリ | チェック内容 |
|---------|------------|
| **正確性** | ロジックエラー、off-by-one、null処理、エッジケース、競合状態 |
| **型安全性** | 型の不一致、安全でないキャスト、`any` の使用、ジェネリクスの欠落 |
| **パターン準拠** | プロジェクト規約に一致（命名、ファイル構造、エラーハンドリング、インポート） |
| **セキュリティ** | インジェクション、認証ギャップ、シークレット露出、SSRF、パストラバーサル、XSS |
| **パフォーマンス** | N+1クエリ、インデックスの欠落、無制限ループ、メモリリーク、大きなペイロード |
| **完全性** | テストの欠落、エラーハンドリングの欠落、不完全なマイグレーション、ドキュメントの欠落 |
| **保守性** | デッドコード、マジックナンバー、深いネスト、不明確な命名、型の欠落 |

各発見事項に重大度を割り当て:

| 重大度 | 意味 | アクション |
|--------|------|----------|
| **CRITICAL** | セキュリティ脆弱性またはデータ損失リスク | マージ前に必ず修正 |
| **HIGH** | 問題を引き起こす可能性の高いバグまたはロジックエラー | マージ前に修正すべき |
| **MEDIUM** | コード品質の問題またはベストプラクティスの欠落 | 修正推奨 |
| **LOW** | スタイルの指摘または軽微な提案 | オプション |

### フェーズ 4 — バリデーション

利用可能なバリデーションコマンドを実行:

設定ファイル（`package.json`、`Cargo.toml`、`go.mod`、`pyproject.toml` など）からプロジェクトタイプを検出し、適切なコマンドを実行:

**Node.js / TypeScript**（`package.json` あり）:
```bash
npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null  # 型チェック
npm run lint                                                    # Lint
npm test                                                        # テスト
npm run build                                                   # ビルド
```

**Rust**（`Cargo.toml` あり）:
```bash
cargo clippy -- -D warnings  # Lint
cargo test                   # テスト
cargo build                  # ビルド
```

**Go**（`go.mod` あり）:
```bash
go vet ./...    # Lint
go test ./...   # テスト
go build ./...  # ビルド
```

**Python**（`pyproject.toml` / `setup.py` あり）:
```bash
pytest  # テスト
```

検出されたプロジェクトタイプに該当するコマンドのみを実行。各コマンドの合格/不合格を記録。

### フェーズ 5 — 判定

発見事項に基づく推奨を形成:

| 条件 | 判定 |
|------|------|
| CRITICAL/HIGH問題ゼロ、バリデーション合格 | **APPROVE** |
| MEDIUM/LOW問題のみ、バリデーション合格 | コメント付き**APPROVE** |
| HIGH問題あり、またはバリデーション失敗 | **REQUEST CHANGES** |
| CRITICAL問題あり | **BLOCK** — マージ前に必ず修正 |

特殊ケース:
- ドラフトPR → 常に **COMMENT** を使用（承認/ブロックではない）
- ドキュメント/設定変更のみ → 軽量レビュー、正確性に焦点
- 明示的な `--approve` または `--request-changes` フラグ → 判定をオーバーライド（ただし全発見事項を報告）

### フェーズ 6 — レポート

レビューアーティファクトを `.claude/PRPs/reviews/pr-<NUMBER>-review.md` に作成:

```markdown
# PR Review: #<NUMBER> — <TITLE>

**レビュー日**: <date>
**作者**: <author>
**ブランチ**: <head> → <base>
**判定**: APPROVE | REQUEST CHANGES | BLOCK

## サマリー
<1-2文の全体的な評価>

## 発見事項

### CRITICAL
<発見事項または "なし">

### HIGH
<発見事項または "なし">

### MEDIUM
<発見事項または "なし">

### LOW
<発見事項または "なし">

## バリデーション結果

| チェック | 結果 |
|---------|------|
| 型チェック | 合格 / 失敗 / スキップ |
| Lint | 合格 / 失敗 / スキップ |
| テスト | 合格 / 失敗 / スキップ |
| ビルド | 合格 / 失敗 / スキップ |

## レビュー済みファイル
<変更タイプ付きファイルリスト: 追加/変更/削除>
```

### フェーズ 7 — 公開

GitHubにレビューを投稿:

```bash
# APPROVEの場合
gh pr review <NUMBER> --approve --body "<レビューのサマリー>"

# REQUEST CHANGESの場合
gh pr review <NUMBER> --request-changes --body "<必要な修正を含むサマリー>"

# COMMENTのみの場合（ドラフトPRまたは情報提供）
gh pr review <NUMBER> --comment --body "<サマリー>"
```

特定の行へのインラインコメントには、GitHubレビューコメントAPIを使用:
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" \
  -f body="<comment>" \
  -f path="<file>" \
  -F line=<line-number> \
  -f side="RIGHT" \
  -f commit_id="$(gh pr view <NUMBER> --json headRefOid --jq .headRefOid)"
```

または、複数のインラインコメントを一度に含む単一レビューを投稿:
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/reviews" \
  -f event="COMMENT" \
  -f body="<全体サマリー>" \
  --input comments.json  # [{"path": "file", "line": N, "body": "comment"}, ...]
```

### フェーズ 8 — 出力

ユーザーに報告:

```
PR #<NUMBER>: <TITLE>
判定: <APPROVE|REQUEST_CHANGES|BLOCK>

問題: <critical_count> critical, <high_count> high, <medium_count> medium, <low_count> low
バリデーション: <pass_count>/<total_count> チェック合格

アーティファクト:
  レビュー: .claude/PRPs/reviews/pr-<NUMBER>-review.md
  GitHub: <PR URL>

次のステップ:
  - <判定に基づく文脈的な提案>
```

---

## エッジケース

- **`gh` CLIがない**: ローカルのみのレビューにフォールバック（diffを読み、GitHub公開をスキップ）。ユーザーに警告。
- **ブランチの乖離**: レビュー前に `git fetch origin && git rebase origin/<base>` を提案。
- **大きなPR（50ファイル超）**: レビュー範囲について警告。まずソース変更、次にテスト、次に設定/ドキュメントに焦点を当てる。
