---
name: promote
description: プロジェクトスコープのインスティンクトをグローバルスコープに昇格
command: true
---

# Promoteコマンド

continuous-learning-v2でインスティンクトをプロジェクトスコープからグローバルスコープに昇格させます。

## 実装

プラグインルートパスを使用してインスティンクトCLIを実行:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" promote [instinct-id] [--force] [--dry-run]
```

`CLAUDE_PLUGIN_ROOT` が設定されていない場合（手動インストール）:

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py promote [instinct-id] [--force] [--dry-run]
```

## 使用方法

```bash
/promote                      # 昇格候補を自動検出
/promote --dry-run            # 自動昇格候補をプレビュー
/promote --force              # プロンプトなしで適格な候補をすべて昇格
/promote grep-before-edit     # 現在のプロジェクトから1つの特定のインスティンクトを昇格
```

## 処理内容

1. 現在のプロジェクトを検出
2. `instinct-id` が提供された場合、そのインスティンクトのみを昇格（現在のプロジェクトに存在する場合）
3. それ以外の場合、以下の条件を満たすクロスプロジェクト候補を検索:
   - 少なくとも2つのプロジェクトに出現
   - 信頼度閾値を満たす
4. 昇格したインスティンクトを `~/.claude/homunculus/instincts/personal/` に `scope: global` で書き込み
