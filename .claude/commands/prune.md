---
name: prune
description: 30日以上経過した未昇格の保留インスティンクトを削除
command: true
---

# 保留インスティンクトの整理

自動生成されたがレビューも昇格もされていない、期限切れの保留インスティンクトを削除します。

## 実装

プラグインルートパスを使用してインスティンクトCLIを実行:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" prune
```

`CLAUDE_PLUGIN_ROOT` が設定されていない場合（手動インストール）:

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py prune
```

## 使用方法

```
/prune                    # 30日以上経過したインスティンクトを削除
/prune --max-age 60      # カスタム経過日数閾値（日）
/prune --dry-run         # 削除せずにプレビュー
```
