---
description: "Lint、Format、TypeCheck、Build、Testを一括実行してコード品質を確認"
---

# コード品質チェック

以下のコマンドを順番に実行して、コード品質を確認してください。

## 実行手順

<!-- プロジェクトに応じてコマンドを調整 -->

1. **Lint修正**

```bash
# 例: pnpm run lint:fix / npx expo lint / cargo clippy
```

2. **フォーマット**

```bash
# 例: pnpm run format / cargo fmt
```

3. **型チェック**

```bash
# 例: pnpm run typecheck / npx tsc --noEmit
```

4. **ビルド**

```bash
# 例: pnpm run build / cargo build / flutter build
```

5. **テスト**

```bash
# 例: pnpm test:run / cargo test / flutter test
```

## 結果報告

- エラーがあれば修正案を提示
- 全て成功なら「全チェック通過（テスト N 件）」と報告
