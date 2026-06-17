---
name: exa-search
description: Neural search via Exa MCP for web, code, and company research. Use when the user needs web search, code examples, company intel, people lookup, or AI-powered deep research with Exa's neural search engine.
origin: ECC
---

# Exa Search

Exa MCP サーバーを介した、Web コンテンツ、コード、企業、人物のニューラル検索です。

## 起動条件

- ユーザーが最新の Web 情報やニュースを必要としている場合
- コード例、API ドキュメント、技術リファレンスを検索する場合
- 企業、競合他社、市場プレイヤーをリサーチする場合
- 特定のドメインの専門家プロフィールや人物を探す場合
- 開発タスクのバックグラウンドリサーチを実行する場合
- ユーザーが「検索して」「調べて」「探して」「最新情報は？」と言った場合

## MCP の要件

Exa MCP サーバーの設定が必要です。`~/.claude.json` に追加してください：

```json
"exa-web-search": {
  "command": "npx",
  "args": ["-y", "exa-mcp-server"],
  "env": { "EXA_API_KEY": "YOUR_EXA_API_KEY_HERE" }
}
```

API キーは [exa.ai](https://exa.ai) で取得できます。
このリポジトリの現在の Exa セットアップでは、ここで公開されるツールサーフェスは `web_search_exa` と `get_code_context_exa` です。
Exa サーバーが追加のツールを公開している場合、ドキュメントやプロンプトで依存する前にそれらの正確な名前を確認してください。

## コアツール

### web_search_exa
最新の情報、ニュース、ファクトのための汎用 Web 検索です。

```
web_search_exa(query: "latest AI developments 2026", numResults: 5)
```

**パラメータ：**

| パラメータ | 型 | デフォルト | 備考 |
|-------|------|---------|-------|
| `query` | string | 必須 | 検索クエリ |
| `numResults` | number | 8 | 結果の数 |
| `type` | string | `auto` | 検索モード |
| `livecrawl` | string | `fallback` | 必要時にライブクロールを優先 |
| `category` | string | なし | オプションのフォーカス（`company` や `research paper` など） |

### get_code_context_exa
GitHub、Stack Overflow、ドキュメントサイトからコード例やドキュメントを検索します。

```
get_code_context_exa(query: "Python asyncio patterns", tokensNum: 3000)
```

**パラメータ：**

| パラメータ | 型 | デフォルト | 備考 |
|-------|------|---------|-------|
| `query` | string | 必須 | コードまたは API 検索クエリ |
| `tokensNum` | number | 5000 | コンテンツトークン数（1000-50000） |

## 使い方パターン

### クイックルックアップ
```
web_search_exa(query: "Node.js 22 new features", numResults: 3)
```

### コードリサーチ
```
get_code_context_exa(query: "Rust error handling patterns Result type", tokensNum: 3000)
```

### 企業・人物リサーチ
```
web_search_exa(query: "Vercel funding valuation 2026", numResults: 3, category: "company")
web_search_exa(query: "site:linkedin.com/in AI safety researchers Anthropic", numResults: 5)
```

### 技術的ディープダイブ
```
web_search_exa(query: "WebAssembly component model status and adoption", numResults: 5)
get_code_context_exa(query: "WebAssembly component model examples", tokensNum: 4000)
```

## ヒント

- 最新情報、企業調査、幅広い発見には `web_search_exa` を使用してください
- `site:`、引用フレーズ、`intitle:` などの検索演算子を使用して結果を絞り込んでください
- 焦点を絞ったコードスニペットには低い `tokensNum`（1000-2000）、包括的なコンテキストには高い値（5000+）を使用してください
- 一般的な Web ページではなく API の使用法やコード例が必要な場合は `get_code_context_exa` を使用してください

## 関連スキル

- `deep-research` — firecrawl + exa を組み合わせた完全なリサーチワークフロー
- `market-research` — 意思決定フレームワークを備えたビジネス向けリサーチ
