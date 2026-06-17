---
name: projects
description: 既知のプロジェクトとそのインスティンクト統計を一覧表示
command: true
---

# Projectsコマンド

continuous-learning-v2のプロジェクトレジストリエントリとプロジェクトごとのインスティンクト/オブザベーション数を一覧表示します。

## 実装

プラグインルートパスを使用してインスティンクトCLIを実行:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" projects
```

`CLAUDE_PLUGIN_ROOT` が設定されていない場合（手動インストール）:

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py projects
```

## 使用方法

```bash
/projects
```

## 処理内容

1. `~/.claude/homunculus/projects.json` を読み取り
2. 各プロジェクトについて表示:
   - プロジェクト名、ID、ルート、リモート
   - 個人および継承インスティンクト数
   - オブザベーションイベント数
   - 最終確認タイムスタンプ
3. グローバルインスティンクトの合計も表示
