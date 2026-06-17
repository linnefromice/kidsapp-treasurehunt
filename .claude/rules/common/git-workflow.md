# Gitワークフロー

## コミットメッセージ形式

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

注: 属性は ~/.claude/settings.json でグローバルに無効化されています。

## プルリクエストワークフロー

PR作成時:
1. 完全なコミット履歴を分析する（最新のコミットだけでなく）
2. `git diff [base-branch]...HEAD` ですべての変更を確認する
3. 包括的なPRサマリーを作成する
4. TODOを含むテスト計画を記載する
5. 新規ブランチの場合は `-u` フラグでプッシュする

> Git操作前の完全な開発プロセス（計画、TDD、コードレビュー）については、
> [development-workflow.md](./development-workflow.md) を参照してください。
