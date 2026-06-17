---
name: deployment-patterns
description: Deployment workflows, CI/CD pipeline patterns, Docker containerization, health checks, rollback strategies, and production readiness checklists for web applications.
origin: ECC
---

# Deployment Patterns

本番デプロイワークフローと CI/CD のベストプラクティスです。

## 起動条件

- CI/CD パイプラインのセットアップ
- アプリケーションの Docker 化
- デプロイ戦略の計画（blue-green、canary、rolling）
- ヘルスチェックとレディネスプローブの実装
- 本番リリースの準備
- 環境固有の設定の構成

## デプロイ戦略

### Rolling Deployment（デフォルト）

インスタンスを段階的に置き換えます — ロールアウト中は旧バージョンと新バージョンが同時に実行されます。

```
Instance 1: v1 → v2  (update first)
Instance 2: v1        (still running v1)
Instance 3: v1        (still running v1)

Instance 1: v2
Instance 2: v1 → v2  (update second)
Instance 3: v1

Instance 1: v2
Instance 2: v2
Instance 3: v1 → v2  (update last)
```

**メリット:** ゼロダウンタイム、段階的ロールアウト
**デメリット:** 2つのバージョンが同時に実行される — 後方互換性のある変更が必要
**使用タイミング:** 標準的なデプロイ、後方互換性のある変更

### Blue-Green Deployment

2つの同一環境を実行します。トラフィックをアトミックに切り替えます。

```
Blue  (v1) ← traffic
Green (v2)   idle, running new version

# After verification:
Blue  (v1)   idle (becomes standby)
Green (v2) ← traffic
```

**メリット:** 即座のロールバック（blue に切り戻し）、クリーンなカットオーバー
**デメリット:** デプロイ中に2倍のインフラが必要
**使用タイミング:** クリティカルなサービス、問題に対するゼロトレランス

### Canary Deployment

まず少量のトラフィックを新バージョンにルーティングします。

```
v1: 95% of traffic
v2:  5% of traffic  (canary)

# If metrics look good:
v1: 50% of traffic
v2: 50% of traffic

# Final:
v2: 100% of traffic
```

**メリット:** フルロールアウト前に実トラフィックで問題を検出
**デメリット:** トラフィック分割インフラとモニタリングが必要
**使用タイミング:** 高トラフィックサービス、リスクの高い変更、フィーチャーフラグ

## Docker

### Multi-Stage Dockerfile (Node.js)

```dockerfile
# Stage 1: Install dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

# Stage 2: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
RUN npm prune --production

# Stage 3: Production image
FROM node:22-alpine AS runner
WORKDIR /app

RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001
USER appuser

COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

### Multi-Stage Dockerfile (Go)

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM alpine:3.19 AS runner
RUN apk --no-cache add ca-certificates
RUN adduser -D -u 1001 appuser
USER appuser

COPY --from=builder /server /server

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/health || exit 1
CMD ["/server"]
```

### Multi-Stage Dockerfile (Python/Django)

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

FROM python:3.12-slim AS runner
WORKDIR /app

RUN useradd -r -u 1001 appuser
USER appuser

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

### Docker ベストプラクティス

```
# 良いプラクティス
- 特定のバージョンタグを使用（node:22-alpine、node:latest ではない）
- マルチステージビルドでイメージサイズを最小化
- 非 root ユーザーとして実行
- 依存関係ファイルを先にコピー（レイヤーキャッシュ）
- .dockerignore で node_modules、.git、tests を除外
- HEALTHCHECK 命令を追加
- docker-compose や k8s でリソース制限を設定

# 悪いプラクティス
- root として実行
- :latest タグの使用
- リポジトリ全体を1つの COPY レイヤーでコピー
- 本番イメージに開発依存関係をインストール
- イメージにシークレットを保存（環境変数またはシークレットマネージャーを使用）
```

## CI/CD パイプライン

### GitHub Actions（標準パイプライン）

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Deploy to production
        run: |
          # Platform-specific deployment command
          # Railway: railway up
          # Vercel: vercel --prod
          # K8s: kubectl set image deployment/app app=ghcr.io/${{ github.repository }}:${{ github.sha }}
          echo "Deploying ${{ github.sha }}"
```

### パイプラインステージ

```
PR opened:
  lint → typecheck → unit tests → integration tests → preview deploy

Merged to main:
  lint → typecheck → unit tests → integration tests → build image → deploy staging → smoke tests → deploy production
```

## ヘルスチェック

### ヘルスチェックエンドポイント

```typescript
// Simple health check
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// Detailed health check (for internal monitoring)
app.get("/health/detailed", async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    externalApi: await checkExternalApi(),
  };

  const allHealthy = Object.values(checks).every(c => c.status === "ok");

  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? "ok" : "degraded",
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || "unknown",
    uptime: process.uptime(),
    checks,
  });
});

async function checkDatabase(): Promise<HealthCheck> {
  try {
    await db.query("SELECT 1");
    return { status: "ok", latency_ms: 2 };
  } catch (err) {
    return { status: "error", message: "Database unreachable" };
  }
}
```

### Kubernetes プローブ

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 30
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 2

startupProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 30    # 30 * 5s = 150s max startup time
```

## 環境設定

### Twelve-Factor App パターン

```bash
# All config via environment variables — never in code
DATABASE_URL=postgres://user:pass@host:5432/db
REDIS_URL=redis://host:6379/0
API_KEY=${API_KEY}           # injected by secrets manager
LOG_LEVEL=info
PORT=3000

# Environment-specific behavior
NODE_ENV=production          # or staging, development
APP_ENV=production           # explicit app environment
```

### 設定のバリデーション

```typescript
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "staging", "production"]),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
});

// Validate at startup — fail fast if config is wrong
export const env = envSchema.parse(process.env);
```

## ロールバック戦略

### 即座のロールバック

```bash
# Docker/Kubernetes: point to previous image
kubectl rollout undo deployment/app

# Vercel: promote previous deployment
vercel rollback

# Railway: redeploy previous commit
railway up --commit <previous-sha>

# Database: rollback migration (if reversible)
npx prisma migrate resolve --rolled-back <migration-name>
```

### ロールバックチェックリスト

- [ ] 前のイメージ/アーティファクトが利用可能でタグ付けされている
- [ ] データベースマイグレーションが後方互換性あり（破壊的変更なし）
- [ ] フィーチャーフラグでデプロイなしに新機能を無効化可能
- [ ] エラーレートスパイクのモニタリングアラートが設定済み
- [ ] 本番リリース前にステージングでロールバックをテスト済み

## 本番レディネスチェックリスト

本番デプロイの前に：

### アプリケーション
- [ ] すべてのテストがパス（ユニット、統合、E2E）
- [ ] コードや設定ファイルにハードコードされたシークレットがない
- [ ] エラーハンドリングがすべてのエッジケースをカバー
- [ ] ログが構造化（JSON）され PII を含まない
- [ ] ヘルスチェックエンドポイントが意味のあるステータスを返す

### インフラ
- [ ] Docker イメージが再現可能にビルド（バージョン固定）
- [ ] 環境変数がドキュメント化され起動時にバリデーション
- [ ] リソース制限が設定（CPU、メモリ）
- [ ] 水平スケーリングが設定（最小/最大インスタンス数）
- [ ] すべてのエンドポイントで SSL/TLS が有効

### モニタリング
- [ ] アプリケーションメトリクスがエクスポート（リクエストレート、レイテンシー、エラー）
- [ ] エラーレート > 閾値のアラートが設定
- [ ] ログ集約がセットアップ（構造化ログ、検索可能）
- [ ] ヘルスエンドポイントの稼働率モニタリング

### セキュリティ
- [ ] 依存関係の CVE スキャン
- [ ] CORS が許可オリジンのみに設定
- [ ] パブリックエンドポイントでレートリミットが有効
- [ ] 認証と認可が検証済み
- [ ] セキュリティヘッダーが設定（CSP、HSTS、X-Frame-Options）

### オペレーション
- [ ] ロールバック計画がドキュメント化されテスト済み
- [ ] データベースマイグレーションが本番サイズのデータでテスト済み
- [ ] 一般的な障害シナリオの Runbook
- [ ] オンコールローテーションとエスカレーションパスが定義
