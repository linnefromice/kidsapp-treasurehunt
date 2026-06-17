---
name: mcp-server-patterns
description: Build MCP servers with Node/TypeScript SDK — tools, resources, prompts, Zod validation, stdio vs Streamable HTTP. Use Context7 or official MCP docs for latest API.
origin: ECC
---

# MCP サーバーパターン

Model Context Protocol（MCP）は、AI アシスタントがサーバーからツールを呼び出し、リソースを読み取り、プロンプトを使用することを可能にします。MCP サーバーの構築やメンテナンス時にこのスキルを使用してください。SDK API は進化しています。現在のメソッド名とシグネチャについては Context7（"MCP" で query-docs）または公式 MCP ドキュメントを確認してください。

ある機能をルール、スキル、MCP、あるいは単純な CLI/API ワークフローのいずれとして実装すべきか、という広い範囲のルーティング判断については [docs/capability-surface-selection.md](../../docs/capability-surface-selection.md) を参照してください。

## 使用タイミング

使用シーン: 新しい MCP サーバーの実装、ツールやリソースの追加、stdio vs HTTP の選択、SDK のアップグレード、MCP 登録やトランスポートの問題のデバッグ。

## 仕組み

### コアコンセプト

- **Tools**: モデルが呼び出せるアクション（例: 検索、コマンド実行）。SDK バージョンに応じて `registerTool()` または `tool()` で登録します。
- **Resources**: モデルがフェッチできる読み取り専用データ（例: ファイル内容、API レスポンス）。`registerResource()` または `resource()` で登録します。ハンドラーは通常 `uri` 引数を受け取ります。
- **Prompts**: クライアントが表示できる再利用可能なパラメータ化されたプロンプトテンプレート（例: Claude Desktop 内）。`registerPrompt()` または同等のメソッドで登録します。
- **Transport**: ローカルクライアント（例: Claude Desktop）には stdio。リモート（Cursor、クラウド）には **Streamable HTTP** が推奨。レガシー HTTP/SSE は後方互換性のためのみ。

Node/TypeScript SDK は `tool()` / `resource()` または `registerTool()` / `registerResource()` を公開する場合があります。公式 SDK は時間とともに変更されています。常に現在の [MCP ドキュメント](https://modelcontextprotocol.io) または Context7 で検証してください。

### stdio での接続

ローカルクライアントの場合、stdio トランスポートを作成してサーバーの connect メソッドに渡します。正確な API は SDK バージョンによって異なります。現在のパターンについては公式 MCP ドキュメントまたは Context7 で "MCP stdio server" を参照してください。

サーバーロジック（ツール + リソース）はトランスポートから独立させ、エントリポイントで stdio または HTTP をプラグインできるようにしてください。

### リモート（Streamable HTTP）

Cursor、クラウド、その他のリモートクライアントには、**Streamable HTTP**（現在の仕様では単一の MCP HTTP エンドポイント）を使用します。後方互換性が必要な場合のみレガシー HTTP/SSE をサポートしてください。

## 例

### インストールとサーバーセットアップ

```bash
npm install @modelcontextprotocol/sdk zod
```

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({ name: "my-server", version: "1.0.0" });
```

お使いの SDK バージョンが提供する API を使用してツールとリソースを登録します。一部のバージョンは `server.tool(name, description, schema, handler)`（位置引数）を使用し、他は `server.tool({ name, description, inputSchema }, handler)` または `registerTool()` を使用します。リソースも同様です。コピペエラーを避けるため、現在の `@modelcontextprotocol/sdk` シグネチャについて公式 MCP ドキュメントまたは Context7 を確認してください。

入力バリデーションには **Zod**（または SDK が推奨するスキーマフォーマット）を使用してください。

## ベストプラクティス

- **スキーマファースト**: すべてのツールに入力スキーマを定義し、パラメータと返り値の形状をドキュメント化します。
- **エラー**: モデルが解釈できる構造化されたエラーまたはメッセージを返します。生のスタックトレースは避けてください。
- **冪等性**: リトライが安全になるよう、可能な限り冪等なツールを優先します。
- **レートとコスト**: 外部 API を呼び出すツールの場合、レート制限とコストを考慮し、ツールの説明にドキュメント化します。
- **バージョニング**: package.json で SDK バージョンを固定し、アップグレード時にリリースノートを確認します。

## 公式 SDK とドキュメント

- **JavaScript/TypeScript**: `@modelcontextprotocol/sdk`（npm）。現在の登録とトランスポートパターンについては Context7 でライブラリ名 "MCP" を使用してください。
- **Go**: GitHub の公式 Go SDK（`modelcontextprotocol/go-sdk`）。
- **C#**: .NET 用公式 C# SDK。
