# 宝の地図 世界観化（マップ・ビジュアル改善）設計

**Goal:** 宝の地図ホームを「単色グラデ + 直線破線 + 白丸ノード」から「羊皮紙風背景 +
Bézier 曲線ルート + 足跡 + リッチな円形ノードバッジ」へ引き上げ、古地図のワクワク感を出す。

**位置づけ:** ビジュアル改善ガイド 2026 の D 章・J-4 に対応。**SDK のみ・アセット不要・
追加 package 不要**（`CustomPainter` + `dart:ui` の `PathMetric` のみ）。

---

## 制約（不変条件）

既存テスト（`test/widget/treasure_map_screen_test.dart`）が依存する以下を**壊さない**:

- ノードのキー: `scene-node.<id>`（GestureDetector）/ `node-cleared.<id>` /
  `node-current.<id>` / `node-locked.<id>`（テーマアイコンの Icon に付与、全状態で存在）。
- ヘッダのクリア数テキスト（`0/9` / `1/9` を含む）・タイトル `home.title`。
- アニメーションは `pump()` のみで検証される（`pumpAndSettle()` はパルスで固まる）。
  新規アニメ層も `pump()` 互換であること。

子供向け UX / 性能（README・ガイド H 章）:
- 環境アニメは低振幅・緩ループ・`RepaintBoundary` 隔離・`shouldRepaint` は値変化時のみ true。
- 足跡など装飾要素は数十個以内。失敗を罰しない・急かさない演出に留める。

## レイヤ構成（Stack、下→上）

地図 body の `Stack` を以下の層で再構成する。各 Painter は責務単位で分割し、
`treasure_map_canvas.dart` に切り出す（screen ファイルの肥大化を防ぐ）。

1. **`ParchmentPainter`（静的・`RepaintBoundary`・`shouldRepaint => false`）**
   - ベース: 既存のクリーム→タンの暖色グラデ塗り。
   - 繊維ムラ: `math.Random(7)` で決定論的に生成した淡い半透明の短いストローク多数
     （シード固定なので再描画しても同一。数は ~120 本上限）。
   - 焦げ枠（ヴィネット）: 端を暗く落とす радиальグラデのオーバーレイ。
   - コンパスローズ: 右上に線画（円 + 4 方位の三角 + N 文字）。
2. **`TrailPainter`（`shouldRepaint` は clearedIds 変化時のみ）**
   - ノード中心列を **Bézier 曲線**（`cubicTo`、制御点はセグメントに垂直方向へ
     インデックスで符号反転オフセット = 決定論的な緩いうねり）で 1 本のパスに。
   - 破線は `PathMetric.extractPath` で抽出（package 不要）。クリア済み区間 =
     `brown.shade600`、未クリア = `brown.shade200`。
   - **足跡（静的）**: クリア済み区間に沿って `getTangentForOffset` で位置・角度を取り、
     小判型の足跡を等間隔配置（歩いてきた道筋を表現。未クリア区間には置かない）。
3. **`_CurrentLegFootprints`（アニメ・専用 `RepaintBoundary`）**
   - 現在ノード（unlocked かつ !cleared の最初の 1 つ）へ向かう 1 区間だけに、
     足跡が順番にフェードインする「マーチング」ループ（誘目）。低振幅・緩ループ。
   - 描くのは 1 区間の数個（~8）のみ → 軽量。`AnimationController` repeat。
   - 現在ノードが存在しない（全クリア / 先頭が未解放）の場合は何も描かない。
4. **ノード群（`_MapNode` を強化）**
   - クリア: 金（amber）リング + 白地 + チェック（既存）。
   - 現在: オレンジリング + `MaskFilter.blur` の発光リング（`_pulse` で呼吸）+
     既存の拡大パルス。
   - ロック: セピア寄せ + 半透明（opacity ~0.55）+ 南京錠（既存）。

## 共有ジオメトリ（`treasure_map_canvas.dart`）

- `List<Offset> trailNodeCenters(Size size)` — `kSceneCatalog` の `mapPos` を画素中心へ。
- `Path buildTrailPath(List<Offset> pts)` — 全点を通る曲線パス（決定論的制御点）。
- `Path legPath(List<Offset> pts, int endIndex)` — `endIndex-1 → endIndex` の 1 区間の曲線。
- これらを `TrailPainter` と `_CurrentLegFootprints` が共有し、足跡が必ずルート上に乗る。

## テスト戦略

- 既存 2 テストはそのまま通過（キー・カウント不変）。
- 追加 widget テスト（`treasure_map_screen_test.dart`）:
  - 複数クリア状態（scene01–03 cleared, scene04 current）でレンダリングが例外なく完了し、
    `node-cleared.scene01`〜`03` / `node-current.scene04` / `node-locked.scene05+` が出る。
  - 全 9 シーン解放・全クリアでも例外なく描画（現在ノード無し = マーチング足跡なし）。
- 追加 unit テスト（`test/unit/treasure_map_canvas_test.dart`）:
  - `trailNodeCenters` が `kSceneCatalog.length` 個を返し、各点が size 内。
  - `buildTrailPath` が空でないパス（`computeMetrics().isNotEmpty`）。
  - `legPath` の端点が `trailNodeCenters` の対応点と一致（曲線でも端点は固定）。

## 規制チェック（README §6）

追加 SDK・ネットワーク・データ収集なし。追加 package なし（`CustomPainter` + `dart:ui` の
標準 API のみ）。端末ローカルの描画のみ。

## 変更ファイル

| ファイル | 変更 |
|----------|------|
| `lib/features/treasure_map/widgets/treasure_map_canvas.dart` | 新規: ジオメトリ helper + `ParchmentPainter` + `TrailPainter` |
| `lib/features/treasure_map/treasure_map_screen.dart` | レイヤ再構成 + `_CurrentLegFootprints` + `_MapNode` 強化 |
| `test/widget/treasure_map_screen_test.dart` | 追加テスト |
| `test/unit/treasure_map_canvas_test.dart` | 新規: ジオメトリ helper のテスト |
