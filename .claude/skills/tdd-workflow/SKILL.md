---
name: tdd-workflow
description: Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
origin: ECC
---

# テスト駆動開発ワークフロー

このスキルはすべてのコード開発が包括的なテストカバレッジを伴う TDD 原則に従うことを保証します。

## 起動条件

- 新しい機能や機能性を書く時
- バグや問題を修正する時
- 既存コードをリファクタリングする時
- APIエンドポイントを追加する時
- 新しいコンポーネントを作成する時

## コア原則

### 1. コードの前にテスト
常にテストを最初に書き、次にテストを通すコードを実装する。

### 2. カバレッジ要件
- 最低80%カバレッジ（ユニット + 統合 + E2E）
- すべてのエッジケースをカバー
- エラーシナリオをテスト
- 境界条件を検証

### 3. テストタイプ

#### ユニットテスト
- 個々の関数とユーティリティ
- コンポーネントロジック
- 純粋関数
- ヘルパーとユーティリティ

#### 統合テスト
- APIエンドポイント
- データベース操作
- サービスインタラクション
- 外部APIコール

#### E2E テスト（Playwright）
- クリティカルなユーザーフロー
- 完全なワークフロー
- ブラウザ自動化
- UI インタラクション

### 4. Git チェックポイント
- リポジトリが Git 管理下にある場合、各 TDD ステージの後にチェックポイントコミットを作成する
- ワークフローが完了するまで、これらのチェックポイントコミットを squash やリライトしない
- 各チェックポイントコミットメッセージは、ステージとキャプチャされた正確な根拠を記述する必要がある
- 現在のアクティブブランチで現在のタスクのために作成されたコミットのみをカウントする
- 他のブランチ、以前の無関係な作業、または遠いブランチ履歴のコミットを有効なチェックポイントの根拠として扱わない
- チェックポイントを満たしたとみなす前に、コミットがアクティブブランチの現在の `HEAD` から到達可能で、現在のタスクシーケンスに属することを検証する
- 推奨されるコンパクトなワークフロー:
  - 失敗テストの追加と RED 検証のための 1 コミット
  - 最小限の修正適用と GREEN 検証のための 1 コミット
  - リファクタリング完了のためのオプションの 1 コミット
- テストコミットが明確に RED に対応し、修正コミットが明確に GREEN に対応する場合、根拠のみのための個別コミットは不要

## TDD ワークフローステップ

### ステップ1: ユーザージャーニーを書く
```
[役割]として、[アクション]したい、それにより[メリット]を得る

例:
ユーザーとして、マーケットをセマンティックに検索したい、
それにより正確なキーワードなしでも関連マーケットを見つけられる。
```

### ステップ2: テストケースを生成
各ユーザージャーニーに対して包括的なテストケースを作成:

```typescript
describe('Semantic Search', () => {
  it('returns relevant markets for query', async () => {
    // テスト実装
  })

  it('handles empty query gracefully', async () => {
    // エッジケーステスト
  })

  it('falls back to substring search when Redis unavailable', async () => {
    // フォールバック動作テスト
  })

  it('sorts results by similarity score', async () => {
    // ソートロジックテスト
  })
})
```

### ステップ 3: テスト実行（失敗すべき）
```bash
npm test
# テストは失敗すべき - まだ実装していない
```

このステップは必須であり、すべての本番変更の RED ゲートです。

ビジネスロジックやその他の本番コードを変更する前に、以下のいずれかのパスで有効な RED 状態を検証する必要があります：
- ランタイム RED:
  - 関連するテストターゲットが正常にコンパイルされる
  - 新しいまたは変更されたテストが実際に実行される
  - 結果が RED である
- コンパイル時 RED:
  - 新しいテストがバグのあるコードパスを新たにインスタンス化、参照、または実行する
  - コンパイル失敗自体が意図された RED シグナルである
- いずれの場合も、失敗は意図されたビジネスロジックのバグ、未定義の動作、または欠落した実装によって引き起こされる
- 失敗が無関係な構文エラー、壊れたテストセットアップ、欠落した依存関係、または無関係なリグレッションのみによって引き起こされていない

書かれただけでコンパイルおよび実行されていないテストは RED としてカウントされません。

この RED 状態が確認されるまで本番コードを編集しないでください。

リポジトリが Git 管理下にある場合、このステージが検証された直後にチェックポイントコミットを作成します。
推奨コミットメッセージ形式：
- `test: add reproducer for <feature or bug>`
- 再現テストがコンパイルおよび実行され、意図された理由で失敗した場合、このコミットは RED 検証チェックポイントとしても機能します
- 続行する前に、このチェックポイントコミットが現在のアクティブブランチ上にあることを検証します

### ステップ 4: コードを実装
テストを通す最小限のコードを書きます：

```typescript
// テストに導かれた実装
export async function searchMarkets(query: string) {
  // ここに実装
}
```

リポジトリが Git 管理下にある場合、最小限の修正をステージングしますが、ステップ 5 で GREEN が検証されるまでチェックポイントコミットは延期します。

### ステップ 5: テスト再実行
```bash
npm test
# テストが通るはず
```

修正後に同じ関連テストターゲットを再実行し、以前失敗したテストが GREEN になったことを確認します。

有効な GREEN 結果が得られた後にのみ、リファクタリングに進むことができます。

リポジトリが Git 管理下にある場合、GREEN が検証された直後にチェックポイントコミットを作成します。
推奨コミットメッセージ形式：
- `fix: <feature or bug>`
- 同じ関連テストターゲットが再実行され合格した場合、修正コミットは GREEN 検証チェックポイントとしても機能します
- 続行する前に、このチェックポイントコミットが現在のアクティブブランチ上にあることを検証します

### ステップ 6: リファクタ
テストをグリーンに保ちながらコード品質を改善します：
- 重複を削除
- 命名を改善
- パフォーマンスを最適化
- 可読性を向上

リポジトリが Git 管理下にある場合、リファクタリングが完了しテストがグリーンのままであることを確認した直後にチェックポイントコミットを作成します。
推奨コミットメッセージ形式：
- `refactor: clean up after <feature or bug> implementation`
- TDD サイクルが完了したとみなす前に、このチェックポイントコミットが現在のアクティブブランチ上にあることを検証します

### ステップ 7: カバレッジを確認
```bash
npm run test:coverage
# 80%以上のカバレッジを達成したことを確認
```

## テストパターン

### ユニットテストパターン（Jest/Vitest）
```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### API統合テストパターン
```typescript
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/markets', () => {
  it('returns markets successfully', async () => {
    const request = new NextRequest('http://localhost/api/markets')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const request = new NextRequest('http://localhost/api/markets?limit=invalid')
    const response = await GET(request)

    expect(response.status).toBe(400)
  })

  it('handles database errors gracefully', async () => {
    // データベース障害をモック
    const request = new NextRequest('http://localhost/api/markets')
    // エラーハンドリングをテスト
  })
})
```

### E2Eテストパターン（Playwright）
```typescript
import { test, expect } from '@playwright/test'

test('user can search and filter markets', async ({ page }) => {
  // マーケットページに移動
  await page.goto('/')
  await page.click('a[href="/markets"]')

  // ページがロードされたことを確認
  await expect(page.locator('h1')).toContainText('Markets')

  // マーケットを検索
  await page.fill('input[placeholder="Search markets"]', 'election')

  // デバウンスと結果を待つ
  await page.waitForTimeout(600)

  // 検索結果が表示されたことを確認
  const results = page.locator('[data-testid="market-card"]')
  await expect(results).toHaveCount(5, { timeout: 5000 })

  // 結果に検索語が含まれていることを確認
  const firstResult = results.first()
  await expect(firstResult).toContainText('election', { ignoreCase: true })

  // ステータスでフィルター
  await page.click('button:has-text("Active")')

  // フィルター結果を確認
  await expect(results).toHaveCount(3)
})

test('user can create a new market', async ({ page }) => {
  // 最初にログイン
  await page.goto('/creator-dashboard')

  // マーケット作成フォームを入力
  await page.fill('input[name="name"]', 'Test Market')
  await page.fill('textarea[name="description"]', 'Test description')
  await page.fill('input[name="endDate"]', '2025-12-31')

  // フォームを送信
  await page.click('button[type="submit"]')

  // 成功メッセージを確認
  await expect(page.locator('text=Market created successfully')).toBeVisible()

  // マーケットページへのリダイレクトを確認
  await expect(page).toHaveURL(/\/markets\/test-market/)
})
```

## テストファイル構成

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx          # ユニットテスト
│   │   └── Button.stories.tsx       # Storybook
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # 統合テスト
└── e2e/
    ├── markets.spec.ts               # E2Eテスト
    ├── trading.spec.ts
    └── auth.spec.ts
```

## 外部サービスのモック

### Supabaseモック
```typescript
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: 'Test Market' }],
          error: null
        }))
      }))
    }))
  }
}))
```

### Redisモック
```typescript
jest.mock('@/lib/redis', () => ({
  searchMarketsByVector: jest.fn(() => Promise.resolve([
    { slug: 'test-market', similarity_score: 0.95 }
  ])),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true }))
}))
```

### OpenAIモック
```typescript
jest.mock('@/lib/openai', () => ({
  generateEmbedding: jest.fn(() => Promise.resolve(
    new Array(1536).fill(0.1) // モック1536次元埋め込み
  ))
}))
```

## テストカバレッジ確認

### カバレッジレポート実行
```bash
npm run test:coverage
```

### カバレッジ閾値
```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## 一般的なテストの間違いを避ける

### ❌ 間違い: 実装詳細をテスト
```typescript
// 内部状態をテストしない
expect(component.state.count).toBe(5)
```

### ✅ 正しい: ユーザーに見える動作をテスト
```typescript
// ユーザーに見えるものをテスト
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### ❌ 間違い: 脆いセレクター
```typescript
// 簡単に壊れる
await page.click('.css-class-xyz')
```

### ✅ 正しい: セマンティックセレクター
```typescript
// 変更に強い
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')
```

### ❌ 間違い: テスト分離なし
```typescript
// テストが互いに依存
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* 前のテストに依存 */ })
```

### ✅ 正しい: 独立したテスト
```typescript
// 各テストが独自のデータをセットアップ
test('creates user', () => {
  const user = createTestUser()
  // テストロジック
})

test('updates user', () => {
  const user = createTestUser()
  // 更新ロジック
})
```

## 継続的テスト

### 開発中のウォッチモード
```bash
npm test -- --watch
# ファイル変更時にテストが自動実行
```

### Pre-Commitフック
```bash
# コミット前に毎回実行
npm test && npm run lint
```

### CI/CD統合
```yaml
# GitHub Actions
- name: Run Tests
  run: npm test -- --coverage
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## ベストプラクティス

1. **テストを最初に書く** - 常にTDD
2. **テストごとに1つのアサート** - 単一の動作に焦点
3. **説明的なテスト名** - 何がテストされるか説明
4. **Arrange-Act-Assert** - 明確なテスト構造
5. **外部依存関係をモック** - ユニットテストを分離
6. **エッジケースをテスト** - null、undefined、空、大きい値
7. **エラーパスをテスト** - ハッピーパスだけでなく
8. **テストを高速に保つ** - ユニットテストは各50ms未満
9. **テスト後にクリーンアップ** - 副作用なし
10. **カバレッジレポートをレビュー** - ギャップを特定

## 成功メトリクス

- 80%以上のコードカバレッジを達成
- すべてのテストが通過（グリーン）
- スキップまたは無効化されたテストなし
- 高速なテスト実行（ユニットテストで30秒未満）
- E2Eテストがクリティカルなユーザーフローをカバー
- テストが本番前にバグを検出

---

**覚えておくこと**: テストはオプションではない。自信を持ったリファクタリング、迅速な開発、本番の信頼性を可能にするセーフティネット。
