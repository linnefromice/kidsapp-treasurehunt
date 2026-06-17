---
description: "自然言語によるファイルターゲティング付きのクイックコミット — 何をコミットするか平易な英語で記述"
argument-hint: "[target description]（空欄 = すべての変更）"
---

# スマートコミット

> WirasmによるPRPs-agentic-engから適用。PRPワークフローシリーズの一部です。

**入力**: $ARGUMENTS

---

## フェーズ 1 — 評価

```bash
git status --short
```

出力が空の場合 → 停止: 「コミットするものがありません。」

変更内容のサマリーをユーザーに表示（追加、変更、削除、アントラック）。

---

## フェーズ 2 — 解釈とステージング

`$ARGUMENTS` を解釈してステージング対象を決定:

| 入力 | 解釈 | Gitコマンド |
|------|------|------------|
| *（空欄/空）* | すべてをステージング | `git add -A` |
| `staged` | 既にステージングされたものを使用 | *（git addなし）* |
| `*.ts` や `*.py` など | マッチするglobをステージング | `git add '*.ts'` |
| `except tests` | すべてをステージング後、テストをアンステージ | `git add -A && git reset -- '**/*.test.*' '**/*.spec.*' '**/test_*' 2>/dev/null \|\| true` |
| `only new files` | アントラックファイルのみステージング | `git ls-files --others --exclude-standard \| grep . && git ls-files --others --exclude-standard \| xargs git add` |
| `the auth changes` | status/diffから解釈 — 認証関連ファイルを検索 | `git add <matched files>` |
| 特定のファイル名 | それらのファイルをステージング | `git add <files>` |

自然言語入力（「the auth changes」など）の場合、`git status` の出力と `git diff` をクロスリファレンスして関連ファイルを特定します。どのファイルをなぜステージングするかをユーザーに表示します。

```bash
git add <determined files>
```

ステージング後、確認:
```bash
git diff --cached --stat
```

何もステージングされていない場合は停止: 「説明に一致するファイルがありません。」

---

## フェーズ 3 — コミット

命令形で1行のコミットメッセージを作成:

```
{type}: {description}
```

タイプ:
- `feat` — 新機能
- `fix` — バグ修正
- `refactor` — 動作変更なしのコード再構成
- `docs` — ドキュメント変更
- `test` — テストの追加または更新
- `chore` — ビルド、設定、依存関係
- `perf` — パフォーマンス改善
- `ci` — CI/CD変更

ルール:
- 命令形（「add feature」であり「added feature」ではない）
- タイププレフィックスの後は小文字
- 末尾にピリオドなし
- 72文字以内
- HOWではなくWHATが変わったかを記述

```bash
git commit -m "{type}: {description}"
```

---

## フェーズ 4 — 出力

ユーザーに報告:

```
Committed: {hash_short}
Message:   {type}: {description}
Files:     {count} file(s) changed

次のステップ:
  - git push           → リモートにプッシュ
  - /prp-pr            → プルリクエストを作成
  - /code-review       → プッシュ前にレビュー
```

---

## 例

| 入力 | 動作 |
|------|------|
| `/prp-commit` | すべてをステージング、メッセージを自動生成 |
| `/prp-commit staged` | 既にステージングされたもののみコミット |
| `/prp-commit *.ts` | すべてのTypeScriptファイルをステージングしてコミット |
| `/prp-commit except tests` | テストファイル以外をすべてステージング |
| `/prp-commit the database migration` | statusからDBマイグレーションファイルを検索してステージング |
| `/prp-commit only new files` | アントラックファイルのみステージング |
