---
name: documentation-lookup
description: Use up-to-date library and framework docs via Context7 MCP instead of training data. Activates for setup questions, API references, code examples, or when the user names a framework (e.g. React, Next.js, Prisma).
origin: ECC
---

# Documentation Lookup (Context7)

ユーザーがライブラリ、フレームワーク、または API について質問した場合、トレーニングデータに依存せず、Context7 MCP（ツール `resolve-library-id` と `query-docs`）を通じて最新のドキュメントを取得します。

## コアコンセプト

- **Context7**: ライブドキュメントを公開する MCP サーバーです。ライブラリや API についてはトレーニングデータの代わりにこれを使用します。
- **resolve-library-id**: ライブラリ名とクエリから Context7 互換のライブラリ ID（例：`/vercel/next.js`）を返します。
- **query-docs**: 指定されたライブラリ ID と質問に対するドキュメントとコードスニペットを取得します。有効なライブラリ ID を取得するために、必ず先に resolve-library-id を呼び出してください。

## 使用タイミング

以下の場合にアクティベートします：

- セットアップや設定に関する質問（例：「Next.js のミドルウェアはどう設定する？」）
- ライブラリに依存するコードのリクエスト（「Prisma でクエリを書いて...」）
- API やリファレンス情報が必要な場合（「Supabase の認証メソッドは？」）
- 特定のフレームワークやライブラリへの言及（React、Vue、Svelte、Express、Tailwind、Prisma、Supabase など）

ライブラリ、フレームワーク、または API の正確で最新の動作に依存するリクエストの場合は、常にこのスキルを使用してください。Context7 MCP が設定されているハーネス（例：Claude Code、Cursor、Codex）全体で適用されます。

## 仕組み

### ステップ 1: ライブラリ ID の解決

以下のパラメータで **resolve-library-id** MCP ツールを呼び出します：

- **libraryName**: ユーザーの質問から取得したライブラリまたは製品名（例：`Next.js`、`Prisma`、`Supabase`）。
- **query**: ユーザーの完全な質問。結果の関連性ランキングが向上します。

ドキュメントをクエリする前に、Context7 互換のライブラリ ID（形式 `/org/project` または `/org/project/version`）を取得する必要があります。このステップからの有効なライブラリ ID なしで query-docs を呼び出さないでください。

### ステップ 2: 最適な結果の選択

解決結果から、以下の基準で1つの結果を選択します：

- **名前の一致**: ユーザーが要求したものと完全一致または最も近い一致を優先。
- **ベンチマークスコア**: 高いスコアはドキュメント品質が高いことを示します（100が最高）。
- **ソースの信頼性**: 利用可能な場合、High または Medium の評価を優先。
- **バージョン**: ユーザーがバージョンを指定した場合（例：「React 19」「Next.js 15」）、リストにバージョン固有のライブラリ ID（例：`/org/project/v1.2.0`）があればそれを優先。

### ステップ 3: ドキュメントの取得

以下のパラメータで **query-docs** MCP ツールを呼び出します：

- **libraryId**: ステップ 2 で選択した Context7 ライブラリ ID（例：`/vercel/next.js`）。
- **query**: ユーザーの具体的な質問またはタスク。関連するスニペットを取得するために具体的に記述してください。

制限：1つの質問につき query-docs（または resolve-library-id）を3回以上呼び出さないでください。3回の呼び出し後も回答が不明確な場合、不確実性を明示し、推測ではなく持っている最良の情報を使用してください。

### ステップ 4: ドキュメントの活用

- 取得した最新の情報を使用してユーザーの質問に回答します。
- ドキュメントからの関連コード例を適宜含めます。
- 重要な場合はライブラリやバージョンを明記します（例：「Next.js 15 では...」）。

## 例

### 例：Next.js ミドルウェア

1. `libraryName: "Next.js"`、`query: "How do I set up Next.js middleware?"` で **resolve-library-id** を呼び出します。
2. 結果から、名前とベンチマークスコアで最適な一致（例：`/vercel/next.js`）を選択します。
3. `libraryId: "/vercel/next.js"`、`query: "How do I set up Next.js middleware?"` で **query-docs** を呼び出します。
4. 返されたスニペットとテキストを使用して回答します。関連する場合はドキュメントからの最小限の `middleware.ts` 例を含めます。

### 例：Prisma クエリ

1. `libraryName: "Prisma"`、`query: "How do I query with relations?"` で **resolve-library-id** を呼び出します。
2. 公式の Prisma ライブラリ ID（例：`/prisma/prisma`）を選択します。
3. その `libraryId` とクエリで **query-docs** を呼び出します。
4. ドキュメントからの短いコードスニペットとともに Prisma Client パターン（例：`include` や `select`）を返します。

### 例：Supabase 認証メソッド

1. `libraryName: "Supabase"`、`query: "What are the auth methods?"` で **resolve-library-id** を呼び出します。
2. Supabase ドキュメントのライブラリ ID を選択します。
3. **query-docs** を呼び出し、認証メソッドを要約し、取得したドキュメントからの最小限の例を示します。

## ベストプラクティス

- **具体的にする**: 可能な限りユーザーの完全な質問をクエリとして使用し、関連性を向上させます。
- **バージョンの認識**: ユーザーがバージョンを言及した場合、解決ステップで利用可能であればバージョン固有のライブラリ ID を使用します。
- **公式ソースを優先**: 複数の一致がある場合、コミュニティフォークよりも公式または主要なパッケージを優先します。
- **機密データの取り扱い**: Context7 に送信するクエリから API キー、パスワード、トークン、その他のシークレットを除去してください。resolve-library-id や query-docs に渡す前に、ユーザーの質問にシークレットが含まれている可能性があることを考慮してください。
