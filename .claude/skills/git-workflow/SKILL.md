---
name: git-workflow
description: Git workflow patterns including branching strategies, commit conventions, merge vs rebase, conflict resolution, and collaborative development best practices for teams of all sizes.
origin: ECC
---

# Git Workflow Patterns

Git バージョン管理、ブランチ戦略、協調的開発のベストプラクティスです。

## 起動条件

- 新しいプロジェクトの Git ワークフローをセットアップする場合
- ブランチ戦略を決定する場合（GitFlow、trunk-based、GitHub flow）
- コミットメッセージや PR の説明を書く場合
- マージコンフリクトを解決する場合
- リリースとバージョンタグを管理する場合
- 新しいチームメンバーに Git プラクティスをオンボーディングする場合

## ブランチ戦略

### GitHub Flow（シンプル、ほとんどの場合推奨）

継続的デプロイメントおよび小〜中規模チームに最適です。

```
main (protected, always deployable)
  │
  ├── feature/user-auth      → PR → merge to main
  ├── feature/payment-flow   → PR → merge to main
  └── fix/login-bug          → PR → merge to main
```

**ルール：**
- `main` は常にデプロイ可能
- `main` からフィーチャーブランチを作成
- レビュー準備ができたら Pull Request を作成
- 承認と CI パス後に `main` にマージ
- マージ後すぐにデプロイ

### Trunk-Based Development（高速チーム向け）

強力な CI/CD とフィーチャーフラグを持つチームに最適です。

```
main (trunk)
  │
  ├── short-lived feature (1-2 days max)
  ├── short-lived feature
  └── short-lived feature
```

**ルール：**
- 全員が `main` または非常に短命なブランチにコミット
- フィーチャーフラグで未完成の作業を隠蔽
- マージ前に CI がパスする必要あり
- 1日に複数回デプロイ

### GitFlow（複雑、リリースサイクル駆動）

スケジュールされたリリースやエンタープライズプロジェクトに最適です。

```
main (production releases)
  │
  └── develop (integration branch)
        │
        ├── feature/user-auth
        ├── feature/payment
        │
        ├── release/1.0.0    → merge to main and develop
        │
        └── hotfix/critical  → merge to main and develop
```

**ルール：**
- `main` は本番準備済みコードのみ
- `develop` はインテグレーションブランチ
- フィーチャーブランチは `develop` から作成、`develop` にマージ
- リリースブランチは `develop` から作成、`main` と `develop` にマージ
- ホットフィックスブランチは `main` から作成、`main` と `develop` の両方にマージ

### どれを使うべきか

| 戦略 | チームサイズ | リリース頻度 | 最適な用途 |
|----------|-----------|-----------------|----------|
| GitHub Flow | 任意 | 継続的 | SaaS、Web アプリ、スタートアップ |
| Trunk-Based | 5人以上の経験者 | 1日に複数回 | 高速チーム、フィーチャーフラグ |
| GitFlow | 10人以上 | スケジュール済み | エンタープライズ、規制産業 |

## コミットメッセージ

### Conventional Commits 形式

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### タイプ

| タイプ | 用途 | 例 |
|------|---------|---------|
| `feat` | 新機能 | `feat(auth): add OAuth2 login` |
| `fix` | バグ修正 | `fix(api): handle null response in user endpoint` |
| `docs` | ドキュメント | `docs(readme): update installation instructions` |
| `style` | フォーマット、コード変更なし | `style: fix indentation in login component` |
| `refactor` | コードリファクタリング | `refactor(db): extract connection pool to module` |
| `test` | テストの追加/更新 | `test(auth): add unit tests for token validation` |
| `chore` | メンテナンスタスク | `chore(deps): update dependencies` |
| `perf` | パフォーマンス改善 | `perf(query): add index to users table` |
| `ci` | CI/CD の変更 | `ci: add PostgreSQL service to test workflow` |
| `revert` | 前のコミットの取り消し | `revert: revert "feat(auth): add OAuth2 login"` |

### 良い例と悪い例

```
# BAD: 曖昧でコンテキストがない
git commit -m "fixed stuff"
git commit -m "updates"
git commit -m "WIP"

# GOOD: 明確で具体的、理由を説明
git commit -m "fix(api): retry requests on 503 Service Unavailable

The external API occasionally returns 503 errors during peak hours.
Added exponential backoff retry logic with max 3 attempts.

Closes #123"
```

### コミットメッセージテンプレート

リポジトリルートに `.gitmessage` を作成します：

```
# <type>(<scope>): <subject>
# # Types: feat, fix, docs, style, refactor, test, chore, perf, ci, revert
# Scope: api, ui, db, auth, etc.
# Subject: imperative mood, no period, max 50 chars
#
# [optional body] - explain why, not what
# [optional footer] - Breaking changes, closes #issue
```

有効化：`git config commit.template .gitmessage`

## Merge vs Rebase

### Merge（履歴を保持）

```bash
# Creates a merge commit
git checkout main
git merge feature/user-auth

# Result:
# *   merge commit
# |\
# | * feature commits
# |/
# * main commits
```

**使用タイミング：**
- フィーチャーブランチを `main` にマージする場合
- 正確な履歴を保持したい場合
- 複数人がブランチで作業した場合
- ブランチがプッシュ済みで他の人がベースにしている可能性がある場合

### Rebase（直線的な履歴）

```bash
# Rewrites feature commits onto target branch
git checkout feature/user-auth
git rebase main

# Result:
# * feature commits (rewritten)
# * main commits
```

**使用タイミング：**
- ローカルのフィーチャーブランチを最新の `main` で更新する場合
- 直線的でクリーンな履歴が欲しい場合
- ブランチがローカルのみ（プッシュされていない）の場合
- 自分だけがブランチで作業している場合

### Rebase ワークフロー

```bash
# Update feature branch with latest main (before PR)
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# Fix any conflicts
# Tests should still pass

# Force push (only if you're the only contributor)
git push --force-with-lease origin feature/user-auth
```

### Rebase してはいけない場合

```
# 以下のブランチは絶対に rebase しないでください：
- 共有リポジトリにプッシュ済みのブランチ
- 他の人が作業のベースにしているブランチ
- 保護されたブランチ（main、develop）
- 既にマージ済みのブランチ

# 理由：Rebase は履歴を書き換え、他の人の作業を壊します
```

## Pull Request ワークフロー

### PR タイトル形式

```
<type>(<scope>): <description>

Examples:
feat(auth): add SSO support for enterprise users
fix(api): resolve race condition in order processing
docs(api): add OpenAPI specification for v2 endpoints
```

### PR 説明テンプレート

```markdown
## What

この PR が何をするかの簡潔な説明。

## Why

動機とコンテキストの説明。

## How

強調すべき主要な実装の詳細。

## Testing

- [ ] ユニットテストを追加/更新
- [ ] 統合テストを追加/更新
- [ ] 手動テストを実施

## Screenshots (if applicable)

UI 変更のビフォー/アフタースクリーンショット。

## Checklist

- [ ] プロジェクトのスタイルガイドラインに従っている
- [ ] セルフレビュー完了
- [ ] 複雑なロジックにコメントを追加
- [ ] ドキュメントを更新
- [ ] 新しい警告が発生しない
- [ ] ローカルでテストがパス
- [ ] 関連 issue をリンク

Closes #123
```

### コードレビューチェックリスト

**レビュアー向け：**

- [ ] コードが述べられた問題を解決しているか？
- [ ] 処理されていないエッジケースはないか？
- [ ] コードは読みやすく保守しやすいか？
- [ ] 十分なテストがあるか？
- [ ] セキュリティ上の懸念はないか？
- [ ] コミット履歴がクリーンか（必要に応じて squash 済み）？

**作成者向け：**

- [ ] レビュー依頼前にセルフレビュー完了
- [ ] CI がパス（テスト、lint、typecheck）
- [ ] PR サイズが妥当（500行未満が理想）
- [ ] 単一の機能/修正に関連
- [ ] 説明が変更内容を明確に説明

## コンフリクト解決

### コンフリクトの特定

```bash
# Check for conflicts before merge
git checkout main
git merge feature/user-auth --no-commit --no-ff

# If conflicts, Git will show:
# CONFLICT (content): Merge conflict in src/auth/login.ts
# Automatic merge failed; fix conflicts and then commit the result.
```

### コンフリクトの解決

```bash
# See conflicted files
git status

# View conflict markers in file
# <<<<<<< HEAD
# content from main
# =======
# content from feature branch
# >>>>>>> feature/user-auth

# Option 1: Manual resolution
# Edit file, remove markers, keep correct content

# Option 2: Use merge tool
git mergetool

# Option 3: Accept one side
git checkout --ours src/auth/login.ts    # Keep main version
git checkout --theirs src/auth/login.ts  # Keep feature version

# After resolving, stage and commit
git add src/auth/login.ts
git commit
```

### コンフリクト防止策

```bash
# 1. フィーチャーブランチを小さく短命に保つ
# 2. main に対して頻繁に rebase する
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# 3. 共有ファイルに触れる場合はチームとコミュニケーション
# 4. 長期ブランチの代わりにフィーチャーフラグを使用
# 5. PR を迅速にレビューしてマージ
```

## ブランチ管理

### 命名規則

```
# Feature branches
feature/user-authentication
feature/JIRA-123-payment-integration

# Bug fixes
fix/login-redirect-loop
fix/456-null-pointer-exception

# Hotfixes (production issues)
hotfix/critical-security-patch
hotfix/database-connection-leak

# Releases
release/1.2.0
release/2024-01-hotfix

# Experiments/POCs
experiment/new-caching-strategy
poc/graphql-migration
```

### ブランチのクリーンアップ

```bash
# Delete local branches that are merged
git branch --merged main | grep -v "^\*\|main" | xargs -n 1 git branch -d

# Delete remote-tracking references for deleted remote branches
git fetch -p

# Delete local branch
git branch -d feature/user-auth  # Safe delete (only if merged)
git branch -D feature/user-auth  # Force delete

# Delete remote branch
git push origin --delete feature/user-auth
```

### Stash ワークフロー

```bash
# Save work in progress
git stash push -m "WIP: user authentication"

# List stashes
git stash list

# Apply most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Drop stash
git stash drop stash@{0}
```

## リリース管理

### セマンティックバージョニング

```
MAJOR.MINOR.PATCH

MAJOR: 破壊的変更
MINOR: 新機能、後方互換性あり
PATCH: バグ修正、後方互換性あり

Examples:
1.0.0 → 1.0.1 (patch: bug fix)
1.0.1 → 1.1.0 (minor: new feature)
1.1.0 → 2.0.0 (major: breaking change)
```

### リリースの作成

```bash
# Create annotated tag
git tag -a v1.2.0 -m "Release v1.2.0

Features:
- Add user authentication
- Implement password reset

Fixes:
- Resolve login redirect issue

Breaking Changes:
- None"

# Push tag to remote
git push origin v1.2.0

# List tags
git tag -l

# Delete tag
git tag -d v1.2.0
git push origin --delete v1.2.0
```

### Changelog の生成

```bash
# Generate changelog from commits
git log v1.1.0..v1.2.0 --oneline --no-merges

# Or use conventional-changelog
npx conventional-changelog -i CHANGELOG.md -s
```

## Git の設定

### 必須設定

```bash
# User identity
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Default branch name
git config --global init.defaultBranch main

# Pull behavior (rebase instead of merge)
git config --global pull.rebase true

# Push behavior (push current branch only)
git config --global push.default current

# Auto-correct typos
git config --global help.autocorrect 1

# Better diff algorithm
git config --global diff.algorithm histogram

# Color output
git config --global color.ui auto
```

### 便利なエイリアス

```bash
# Add to ~/.gitconfig
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --oneline --graph --all
    amend = commit --amend --no-edit
    wip = commit -m "WIP"
    undo = reset --soft HEAD~1
    contributors = shortlog -sn
```

### Gitignore パターン

```gitignore
# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
*.o
*.exe

# Environment files
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Test coverage
coverage/

# Cache
.cache/
*.tsbuildinfo
```

## よくあるワークフロー

### 新機能の開始

```bash
# 1. Update main branch
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/user-auth

# 3. Make changes and commit
git add .
git commit -m "feat(auth): implement OAuth2 login"

# 4. Push to remote
git push -u origin feature/user-auth

# 5. Create Pull Request on GitHub/GitLab
```

### 新しい変更で PR を更新

```bash
# 1. Make additional changes
git add .
git commit -m "feat(auth): add error handling"

# 2. Push updates
git push origin feature/user-auth
```

### フォークとアップストリームの同期

```bash
# 1. Add upstream remote (once)
git remote add upstream https://github.com/original/repo.git

# 2. Fetch upstream
git fetch upstream

# 3. Merge upstream/main into your main
git checkout main
git merge upstream/main

# 4. Push to your fork
git push origin main
```

### ミスの取り消し

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo last commit pushed to remote
git revert HEAD
git push origin main

# Undo specific file changes
git checkout HEAD -- path/to/file

# Fix last commit message
git commit --amend -m "New message"

# Add forgotten file to last commit
git add forgotten-file
git commit --amend --no-edit
```

## Git フック

### Pre-Commit フック

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run linting
npm run lint || exit 1

# Run tests
npm test || exit 1

# Check for secrets
if git diff --cached | grep -E '(password|api_key|secret)'; then
    echo "Possible secret detected. Commit aborted."
    exit 1
fi
```

### Pre-Push フック

```bash
#!/bin/bash
# .git/hooks/pre-push

# Run full test suite
npm run test:all || exit 1

# Check for console.log statements
if git diff origin/main | grep -E 'console\.log'; then
    echo "Remove console.log statements before pushing."
    exit 1
fi
```

## アンチパターン

```
# BAD: main に直接コミット
git checkout main
git commit -m "fix bug"

# GOOD: フィーチャーブランチと PR を使用

# BAD: シークレットのコミット
git add .env  # Contains API keys

# GOOD: .gitignore に追加し、環境変数を使用

# BAD: 巨大な PR（1000行以上）
# GOOD: 小さく焦点を絞った PR に分割

# BAD: "Update" のコミットメッセージ
git commit -m "update"
git commit -m "fix"

# GOOD: 説明的なメッセージ
git commit -m "fix(auth): resolve redirect loop after login"

# BAD: パブリック履歴の書き換え
git push --force origin main

# GOOD: パブリックブランチには revert を使用
git revert HEAD

# BAD: 長期間のフィーチャーブランチ（数週間/数ヶ月）
# GOOD: ブランチを短く保ち（数日）、頻繁に rebase

# BAD: 生成されたファイルのコミット
git add dist/
git add node_modules/

# GOOD: .gitignore に追加
```

## クイックリファレンス

| タスク | コマンド |
|------|---------|
| ブランチ作成 | `git checkout -b feature/name` |
| ブランチ切り替え | `git checkout branch-name` |
| ブランチ削除 | `git branch -d branch-name` |
| ブランチマージ | `git merge branch-name` |
| ブランチ rebase | `git rebase main` |
| 履歴表示 | `git log --oneline --graph` |
| 変更表示 | `git diff` |
| 変更ステージ | `git add .` or `git add -p` |
| コミット | `git commit -m "message"` |
| プッシュ | `git push origin branch-name` |
| プル | `git pull origin branch-name` |
| スタッシュ | `git stash push -m "message"` |
| 最後のコミットを取り消し | `git reset --soft HEAD~1` |
| コミットを revert | `git revert HEAD` |
