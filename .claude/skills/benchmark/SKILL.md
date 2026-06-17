---
name: benchmark
description: Use this skill to measure performance baselines, detect regressions before/after PRs, and compare stack alternatives.
origin: ECC
---

# Benchmark — パフォーマンスベースラインとリグレッション検出

## 使用タイミング

- PR の前後でパフォーマンスへの影響を測定する場合
- プロジェクトのパフォーマンスベースラインを設定する場合
- ユーザーから「遅く感じる」と報告があった場合
- ローンチ前にパフォーマンス目標を満たしているか確認する場合
- 自分のスタックを代替案と比較する場合

## 仕組み

### モード 1: Page Performance

ブラウザ MCP 経由で実際のブラウザメトリクスを測定します:

```
1. 各ターゲット URL に遷移
2. Core Web Vitals を測定:
   - LCP (Largest Contentful Paint) — 目標 < 2.5s
   - CLS (Cumulative Layout Shift) — 目標 < 0.1
   - INP (Interaction to Next Paint) — 目標 < 200ms
   - FCP (First Contentful Paint) — 目標 < 1.8s
   - TTFB (Time to First Byte) — 目標 < 800ms
3. リソースサイズを測定:
   - ページ総重量（目標 < 1MB）
   - JS バンドルサイズ（目標 < 200KB gzipped）
   - CSS サイズ
   - 画像重量
   - サードパーティスクリプトの重量
4. ネットワークリクエスト数をカウント
5. レンダリングブロッキングリソースをチェック
```

### モード 2: API Performance

API エンドポイントのベンチマークを行います:

```
1. 各エンドポイントに100回アクセス
2. 測定: p50、p95、p99 レイテンシー
3. 追跡: レスポンスサイズ、ステータスコード
4. 負荷テスト: 10同時リクエスト
5. SLA 目標と比較
```

### モード 3: Build Performance

開発フィードバックループを測定します:

```
1. コールドビルド時間
2. ホットリロード時間（HMR）
3. テストスイートの実行時間
4. TypeScript チェック時間
5. Lint 時間
6. Docker ビルド時間
```

### モード 4: Before/After Comparison

変更前後に実行して影響を測定します:

```
/benchmark baseline    # 現在のメトリクスを保存
# ... 変更を実施 ...
/benchmark compare     # ベースラインと比較
```

出力:
```
| Metric | Before | After | Delta | Verdict |
|--------|--------|-------|-------|---------|
| LCP | 1.2s | 1.4s | +200ms | WARNING: WARN |
| Bundle | 180KB | 175KB | -5KB | ✓ BETTER |
| Build | 12s | 14s | +2s | WARNING: WARN |
```

## 出力

ベースラインは `.ecc/benchmarks/` に JSON として保存されます。Git で追跡されるため、チームでベースラインを共有できます。

## 統合

- CI: すべての PR で `/benchmark compare` を実行
- デプロイ後のモニタリングには `/canary-watch` と組み合わせ
- リリース前の完全チェックリストには `/browser-qa` と組み合わせ
