---
name: design-system
description: Use this skill to generate or audit design systems, check visual consistency, and review PRs that touch styling.
origin: ECC
---

# Design System — デザインシステムの生成と監査

## 使用タイミング

- デザインシステムが必要な新規プロジェクトの開始時
- 既存コードベースのビジュアル一貫性の監査時
- リデザイン前に現状を把握する場合
- UI が「何かおかしい」が原因を特定できない場合
- スタイリングに関わる PR のレビュー時

## 仕組み

### モード 1: Generate Design System

コードベースを分析し、統一的なデザインシステムを生成します:

```
1. CSS/Tailwind/styled-components の既存パターンをスキャン
2. 抽出: カラー、タイポグラフィ、スペーシング、border-radius、シャドウ、ブレークポイント
3. インスピレーションのために競合3サイトを調査（browser MCP 経由）
4. デザイントークンセットを提案（JSON + CSS custom properties）
5. 各決定の根拠を含む DESIGN.md を生成
6. インタラクティブな HTML プレビューページを作成（自己完結型、依存関係なし）
```

出力: `DESIGN.md` + `design-tokens.json` + `design-preview.html`

### モード 2: Visual Audit

UI を10の指標（各0-10点）でスコアリングします:

```
1. カラーの一貫性 — パレットを使用しているか、ランダムな hex 値か？
2. タイポグラフィの階層 — 明確な h1 > h2 > h3 > body > caption か？
3. スペーシングのリズム — 一貫したスケール（4px/8px/16px）か、恣意的か？
4. コンポーネントの一貫性 — 類似要素が類似した見た目か？
5. レスポンシブ対応 — ブレークポイントで滑らかか、崩れるか？
6. ダークモード — 完全か、中途半端か？
7. アニメーション — 意図的か、過剰か？
8. アクセシビリティ — コントラスト比、フォーカス状態、タッチターゲット
9. 情報密度 — 雑然としているか、すっきりしているか？
10. 仕上げ — ホバー状態、トランジション、ローディング状態、空の状態
```

各指標にスコア、具体例、修正箇所（ファイル名:行番号）が付きます。

### モード 3: AI Slop Detection

汎用的な AI 生成デザインパターンを特定します:

```
- すべてに過剰なグラデーション
- 紫から青のデフォルト配色
- 目的のない「グラスモーフィズム」カード
- 丸めるべきでないものへの角丸
- スクロール時の過度なアニメーション
- ストックグラデーション上の中央配置テキストによる汎用的なヒーロー
- 個性のない sans-serif フォントスタック
```

## 例

**SaaS アプリ向けに生成:**
```
/design-system generate --style minimal --palette earth-tones
```

**既存 UI の監査:**
```
/design-system audit --url http://localhost:3000 --pages / /pricing /docs
```

**AI スロップのチェック:**
```
/design-system slop-check
```
