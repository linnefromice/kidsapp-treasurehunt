---
name: project-flow-ops
description: Operate execution flow across GitHub and Linear by triaging issues and pull requests, linking active work, and keeping GitHub public-facing while Linear remains the internal execution layer. Use when the user wants backlog control, PR triage, or GitHub-to-Linear coordination.
origin: ECC
---

# Project Flow Ops

このスキルは、分断された GitHub の issue、PR、Linear タスクを1つの実行フローに統合します。

問題がコーディングではなく調整にある場合に使用します。

## 使用タイミング

- オープンな PR や issue のバックログをトリアージする
- Linear に属すべきものと GitHub のみに残すべきものを判断する
- アクティブな GitHub の作業を社内実行レーンにリンクする
- PR をマージ、ポート/リビルド、クローズ、またはパークに分類する
- レビューコメント、CI の失敗、または古くなった issue が実行をブロックしていないか監査する

## 運用モデル

- **GitHub** はパブリックおよびコミュニティの信頼できる情報源です
- **Linear** はアクティブにスケジュールされた作業の社内実行の信頼できる情報源です
- すべての GitHub issue が Linear issue を必要とするわけではありません
- 作業が以下の場合にのみ Linear を作成または更新します:
  - アクティブ
  - 委譲済み
  - スケジュール済み
  - 部門横断的
  - 社内で追跡するほど重要

## コアワークフロー

### 1. まずパブリックサーフェスを読む

以下を収集します:

- GitHub の issue または PR のステート
- 著者とブランチのステータス
- レビューコメント
- CI ステータス
- リンクされた issue

### 2. 作業を分類する

すべてのアイテムは以下のいずれかのステートになるべきです:

| ステート | 意味 |
|---------|------|
| Merge | 自己完結型、ポリシー準拠、準備完了 |
| Port/Rebuild | 有用なアイデアだが、ECC 内で手動で再ランディングすべき |
| Close | 方向性が違う、古い、安全でない、または重複 |
| Park | 潜在的に有用だが、現在スケジュールされていない |

### 3. Linear が必要かどうかを判断する

以下の場合にのみ Linear を作成または更新します:

- 実行がアクティブに計画されている
- 複数のリポジトリやワークストリームが関与している
- 作業に社内のオーナーシップやシーケンシングが必要
- issue がより大きなプログラムレーンの一部である

すべてを機械的にミラーリングしないでください。

### 4. 2つのシステムの整合性を保つ

作業がアクティブな場合:

- GitHub の issue/PR はパブリックに何が起きているかを伝えるべきです
- Linear は社内でオーナー、優先度、実行レーンを追跡すべきです

作業がリリースまたは却下された場合:

- パブリックな解決結果を GitHub に投稿します
- Linear タスクを適切にマークします

## レビュールール

- タイトル、要約、または信頼のみでマージしないでください。完全な diff を使用します
- 外部ソースの機能は、価値があるが自己完結的でない場合、ECC 内でリビルドすべきです
- CI がレッドの場合は分類して修正またはブロックします。マージ可能なふりをしないでください
- 本当のブロッカーがプロダクトの方向性である場合は、ツールの問題に隠れずそう伝えてください

## 出力フォーマット

以下を返します:

```text
PUBLIC STATUS
- issue / PR state
- CI / review state

CLASSIFICATION
- merge / port-rebuild / close / park
- one-paragraph rationale

LINEAR ACTION
- create / update / no Linear item needed
- project / lane if applicable

NEXT OPERATOR ACTION
- exact next move
```

## 良いユースケース

- 「オープンな PR バックログを監査して、マージすべきものとリビルドすべきものを教えて」
- 「GitHub の issue を ECC 1.x と ECC 2.0 のプログラムレーンにマッピングして」
- 「これに Linear issue が必要か、それとも GitHub のみに残すべきか確認して」
