# テスト要件

## 最低テストカバレッジ: 80%

テストタイプ（すべて必須）:
1. **ユニットテスト** - 個々の関数、ユーティリティ、コンポーネント
2. **統合テスト** - APIエンドポイント、データベース操作
3. **E2Eテスト** - クリティカルなユーザーフロー（言語ごとに選択されたフレームワーク）

## テスト駆動開発

必須ワークフロー:
1. まずテストを書く（RED）
2. テストを実行 - 失敗するはず
3. 最小限の実装を書く（GREEN）
4. テストを実行 - パスするはず
5. リファクタリング（IMPROVE）
6. カバレッジを確認（80%以上）

## テスト失敗のトラブルシューティング

1. **tdd-guide** エージェントを使用する
2. テストの分離を確認する
3. モックが正しいか検証する
4. テストではなく実装を修正する（テストが間違っている場合を除く）

## エージェントサポート

- **tdd-guide** - 新機能に対して積極的に使用、テストファーストを強制

## テスト構造（AAA パターン）

テストには Arrange-Act-Assert の構造を優先してください：

```typescript
test('calculates similarity correctly', () => {
  // Arrange（準備）
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act（実行）
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert（検証）
  expect(similarity).toBe(0)
})
```

### テスト名の付け方

テスト対象の振る舞いを説明する、記述的な名前を使用してください：

```typescript
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
```
