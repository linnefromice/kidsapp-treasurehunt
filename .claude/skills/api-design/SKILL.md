---
name: api-design
description: REST API design patterns including resource naming, status codes, pagination, filtering, error responses, versioning, and rate limiting for production APIs.
origin: ECC
---

# API Design Patterns

一貫性があり開発者フレンドリーな REST API を設計するための規約とベストプラクティスです。

## 起動条件

- 新しい API エンドポイントを設計する場合
- 既存の API コントラクトをレビューする場合
- ページネーション、フィルタリング、ソートを追加する場合
- API のエラーハンドリングを実装する場合
- API バージョニング戦略を計画する場合
- パブリックまたはパートナー向け API を構築する場合

## Resource Design

### URL 構造

```
# リソースは名詞、複数形、小文字、kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# リレーションシップのためのサブリソース
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# CRUD にマッピングされないアクション（動詞は控えめに使用）
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### 命名ルール

```
# GOOD
/api/v1/team-members          # 複数語のリソースには kebab-case
/api/v1/orders?status=active  # フィルタリングにはクエリパラメータ
/api/v1/users/123/orders      # 所有関係にはネストされたリソース

# BAD
/api/v1/getUsers              # URL に動詞
/api/v1/user                  # 単数形（複数形を使用）
/api/v1/team_members          # URL に snake_case
/api/v1/users/123/getOrders   # ネストされたリソースに動詞
```

## HTTP Methods とステータスコード

### メソッドのセマンティクス

| メソッド | 冪等性 | 安全性 | 用途 |
|--------|-----------|------|---------|
| GET | あり | あり | リソースの取得 |
| POST | なし | なし | リソースの作成、アクションのトリガー |
| PUT | あり | なし | リソースの完全な置換 |
| PATCH | なし* | なし | リソースの部分的な更新 |
| DELETE | あり | なし | リソースの削除 |

*PATCH は適切な実装により冪等にすることができます

### ステータス Code Reference

```
# 成功
200 OK                    — GET, PUT, PATCH（レスポンスボディあり）
201 Created               — POST（Location ヘッダーを含める）
204 No Content            — DELETE, PUT（レスポンスボディなし）

# クライアントエラー
400 Bad Request           — バリデーション失敗、不正な JSON
401 Unauthorized          — 認証の欠落または無効
403 Forbidden             — 認証済みだが権限なし
404 Not Found             — リソースが存在しない
409 Conflict              — 重複エントリ、状態の競合
422 Unprocessable Entity  — セマンティックに無効（有効な JSON、不正なデータ）
429 Too Many Requests     — レート制限超過

# サーバーエラー
500 Internal Server Error — 予期しない障害（詳細を公開しない）
502 Bad Gateway           — アップストリームサービスの障害
503 Service Unavailable   — 一時的な過負荷、Retry-After を含める
```

### よくある間違い

```
# BAD: すべてに 200
{ "status": 200, "success": false, "error": "Not found" }

# GOOD: HTTP ステータスコードをセマンティックに使用
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }

# BAD: バリデーションエラーに 500
# GOOD: フィールドレベルの詳細付きで 400 または 422

# BAD: 作成されたリソースに 200
# GOOD: Location ヘッダー付きで 201
HTTP/1.1 201 Created
Location: /api/v1/users/abc-123
```

## Response Format

### 成功レスポンス

```json
{
  "data": {
    "id": "abc-123",
    "email": "alice@example.com",
    "name": "Alice",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

### コレクションレスポンス（ページネーション付き）

```json
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": {
    "total": 142,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1&per_page=20",
    "next": "/api/v1/users?page=2&per_page=20",
    "last": "/api/v1/users?page=8&per_page=20"
  }
}
```

### エラーレスポンス

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "code": "invalid_format"
      },
      {
        "field": "age",
        "message": "Must be between 0 and 150",
        "code": "out_of_range"
      }
    ]
  }
}
```

### レスポンスエンベロープのバリエーション

```typescript
// オプション A: data ラッパー付きエンベロープ（パブリック API に推奨）
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
  links?: PaginationLinks;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: FieldError[];
  };
}

// オプション B: フラットレスポンス（よりシンプル、内部 API でよく使用）
// 成功: リソースを直接返す
// エラー: エラーオブジェクトを返す
// HTTP ステータスコードで区別
```

## Pagination

### オフセットベース（シンプル）

```
GET /api/v1/users?page=2&per_page=20

# 実装
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

**長所:** 実装が簡単、「N ページ目にジャンプ」が可能
**短所:** 大きなオフセットで低速（OFFSET 100000）、同時挿入で不整合

### カーソルベース（スケーラブル）

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

# 実装
SELECT * FROM users
WHERE id > :cursor_id
ORDER BY id ASC
LIMIT 21;  -- has_next を判定するために1件多く取得
```

```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTQzfQ"
  }
}
```

**長所:** 位置に関係なく一定のパフォーマンス、同時挿入でも安定
**短所:** 任意のページへのジャンプ不可、カーソルは不透明

### 使用タイミング Which

| ユースケース | ページネーション方式 |
|----------|----------------|
| 管理画面、小規模データセット（<10K） | オフセット |
| 無限スクロール、フィード、大規模データセット | カーソル |
| パブリック API | カーソル（デフォルト）、オフセット（オプション） |
| 検索結果 | オフセット（ユーザーはページ番号を期待） |

## フィルタリング、ソート、検索

### フィルタリング

```
# 単純な等価
GET /api/v1/orders?status=active&customer_id=abc-123

# 比較演算子（ブラケット表記を使用）
GET /api/v1/products?price[gte]=10&price[lte]=100
GET /api/v1/orders?created_at[after]=2025-01-01

# 複数値（カンマ区切り）
GET /api/v1/products?category=electronics,clothing

# ネストされたフィールド（ドット表記）
GET /api/v1/orders?customer.country=US
```

### ソート

```
# 単一フィールド（降順はプレフィックス -）
GET /api/v1/products?sort=-created_at

# 複数フィールド（カンマ区切り）
GET /api/v1/products?sort=-featured,price,-created_at
```

### 全文検索

```
# 検索クエリパラメータ
GET /api/v1/products?q=wireless+headphones

# フィールド固有の検索
GET /api/v1/users?email=alice
```

### Sparse Fieldsets

```
# 指定されたフィールドのみ返す（ペイロードを削減）
GET /api/v1/users?fields=id,name,email
GET /api/v1/orders?fields=id,total,status&include=customer.name
```

## 認証と認可

### トークンベース認証

```
# Authorization ヘッダーに Bearer トークン
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API キー（サーバー間通信用）
GET /api/v1/data
X-API-Key: sk_live_abc123
```

### 認可パターン

```typescript
// リソースレベル: 所有権を確認
app.get("/api/v1/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: { code: "not_found" } });
  if (order.userId !== req.user.id) return res.status(403).json({ error: { code: "forbidden" } });
  return res.json({ data: order });
});

// ロールベース: 権限を確認
app.delete("/api/v1/users/:id", requireRole("admin"), async (req, res) => {
  await User.delete(req.params.id);
  return res.status(204).send();
});
```

## Rate Limiting

### ヘッダー

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

# 超過時
HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds."
  }
}
```

### Rate Limit Tiers

| ティア | 制限 | ウィンドウ | ユースケース |
|------|-------|--------|----------|
| Anonymous | 30/分 | IP ごと | パブリックエンドポイント |
| Authenticated | 100/分 | ユーザーごと | 標準 API アクセス |
| Premium | 1000/分 | API キーごと | 有料 API プラン |
| Internal | 10000/分 | サービスごと | サービス間通信 |

## バージョニング

### URL パスバージョニング（推奨）

```
/api/v1/users
/api/v2/users
```

**長所:** 明示的、ルーティングが簡単、キャッシュ可能
**短所:** バージョン間で URL が変更される

### ヘッダーバージョニング

```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**長所:** URL がクリーン
**短所:** テストが難しい、指定忘れが起きやすい

### バージョニング戦略

```
1. /api/v1/ から始める — 必要になるまでバージョニングしない
2. アクティブバージョンは最大2つ（現行＋前バージョン）
3. 非推奨化のタイムライン:
   - 非推奨を告知（パブリック API は6ヶ月前の通知）
   - Sunset ヘッダーを追加: Sunset: Sat, 01 Jan 2026 00:00:00 GMT
   - Sunset 日以降は 410 Gone を返す
4. 破壊的でない変更は新バージョン不要:
   - レスポンスへの新しいフィールドの追加
   - 新しいオプションクエリパラメータの追加
   - 新しいエンドポイントの追加
5. 破壊的変更には新バージョンが必要:
   - フィールドの削除またはリネーム
   - フィールド型の変更
   - URL 構造の変更
   - 認証方法の変更
```

## 実装 Patterns

### TypeScript (Next.js API Route)

```typescript
import { z } from "zod";
import { NextRequest, NextResponse } from "next/server";

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createUserSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({
          field: i.path.join("."),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 });
  }

  const user = await createUser(parsed.data);

  return NextResponse.json(
    { data: user },
    {
      status: 201,
      headers: { Location: `/api/v1/users/${user.id}` },
    },
  );
}
```

### Python (Django REST Framework)

```python
from rest_framework import serializers, viewsets, status
from rest_framework.response import Response

class CreateUserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    name = serializers.CharField(max_length=100)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "name", "created_at"]

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateUserSerializer
        return UserSerializer

    def create(self, request):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = UserService.create(**serializer.validated_data)
        return Response(
            {"data": UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
            headers={"Location": f"/api/v1/users/{user.id}"},
        )
```

### Go (net/http)

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid_json", "Invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "validation_error", err.Error())
        return
    }

    user, err := h.service.Create(r.Context(), req)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrEmailTaken):
            writeError(w, http.StatusConflict, "email_taken", "Email already registered")
        default:
            writeError(w, http.StatusInternalServerError, "internal_error", "Internal error")
        }
        return
    }

    w.Header().Set("Location", fmt.Sprintf("/api/v1/users/%s", user.ID))
    writeJSON(w, http.StatusCreated, map[string]any{"data": user})
}
```

## API Design Checklist

新しいエンドポイントをリリースする前に:

- [ ] リソース URL が命名規約に従っている（複数形、kebab-case、動詞なし）
- [ ] 正しい HTTP メソッドを使用している（GET は読み取り、POST は作成など）
- [ ] 適切なステータスコードを返している（すべてに 200 ではない）
- [ ] スキーマで入力がバリデーションされている（Zod、Pydantic、Bean Validation）
- [ ] エラーレスポンスがコードとメッセージ付きの標準フォーマットに従っている
- [ ] リストエンドポイントにページネーションが実装されている（カーソルまたはオフセット）
- [ ] 認証が必要（または明示的にパブリックとマーク）
- [ ] 認可がチェックされている（ユーザーは自分のリソースのみアクセス可能）
- [ ] Rate limiting が設定されている
- [ ] レスポンスが内部の詳細を漏洩していない（スタックトレース、SQL エラー）
- [ ] 既存エンドポイントとの命名の一貫性（camelCase vs snake_case）
- [ ] ドキュメント化されている（OpenAPI/Swagger スペックが更新済み）
