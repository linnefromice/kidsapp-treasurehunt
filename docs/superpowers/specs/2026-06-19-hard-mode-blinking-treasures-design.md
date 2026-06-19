# ハードモード: 宝が消える/現れる（点滅）設計

## 目的

ハードモード（全シーンクリア後に解放）で、未発見の宝が周期的に消えたり現れたりする
視覚＋タイミングの難化要素を追加する。「見えている瞬間を狙って押す」遊びを足しつつ、
本作のゲーム設計原則（失敗を罰しない・急かさない・時間制限なし）を損なわない。

## ゲーム原則との整合（重要）

- **失敗を罰しない**: 消失中の宝をタップしても無反応（ミスバブルすら出さない。`hiddenIds`
  で当たり判定から除外する）。減点・不快音は一切なし。
- **急かさない / 手詰まりを作らない**: 各宝は位相をずらして点滅させ、全宝が同時に消える
  瞬間を作らない。常にいくつかは見えている＝「待たないと何も押せない」時間帯が無い。
- **無制限ヒント**: ヒント中（`_hintingId`）の宝は点滅させず常時表示し、当たり判定も常に
  有効（ヒントは必ず本当に見える）。
- **やさしめのリズム**: 1 周期 ≈ 4 秒。大半（約 70%）は完全可視、消失は短く（約 14%）、
  フェードは緩やか。

## 範囲

- 対象は **ハードモードのみ**。通常モードの挙動は不変。
- 点滅するのは**未発見の宝のみ**。発見済みは常時表示（既存の found グロー維持）。
- ダミー（おとり）は点滅させない（当たり判定対象外で、難化はターゲット側で十分）。
- 完了時は点滅クロックを停止。

## 設計

### 1. 点滅モデル（純関数・テスト対象）

`lib/features/seek_find/seek_find_logic.dart` に追加する。描画と当たり判定の両方が
**同じ関数**を使うことで「見えている＝押せる」を保証する（既存 `scaledTreasureRect` と同思想）。

```dart
/// 1 周期の長さ（やさしめ）。
const Duration kBlinkCyclePeriod = Duration(milliseconds: 4000);

/// この不透明度以上を「見えている」とみなし、当たり判定を有効にする境界。
const double kBlinkVisibleThreshold = 0.5;

/// ターゲット slot（0..count-1 の安定インデックス）の、共有クロック clock
/// （0.0–1.0, 周期内の位置）における表示不透明度（0.0–1.0）。
/// count に応じて位相をずらし、全宝が同時に消えないようにする。
double treasureBlinkOpacity({
  required int slot,
  required int count,
  required double clock,
});
```

1 周期内のフェーズ p の不透明度プロファイル（p = (clock + slot/count) % 1.0）:

| 区間 | 不透明度 |
|------|----------|
| `[0.00, 0.70)` | 1.0（完全可視） |
| `[0.70, 0.78)` | 1.0→0.0（フェードアウト） |
| `[0.78, 0.92)` | 0.0（消失） |
| `[0.92, 1.00)` | 0.0→1.0（フェードイン） |

`count <= 0` のときは offset 0（ゼロ除算ガード）。

### 2. 当たり判定: 消失中の宝を除外

`findHitTargetId` に任意引数 `Set<String> hiddenIds = const {}` を追加。`foundIds` と同様に
スキップする。通常モードでは空集合のため挙動不変。

### 3. 画面側の配線（`_SceneViewState`）

- `with SingleTickerProviderStateMixin` を付与。
- `AnimationController? _blinkClock`。ハードモードのときだけ `initState` で
  `duration: kBlinkCyclePeriod` の `..repeat()` を生成。`dispose` で破棄。完了時 `stop()`。
- `_hiddenTargetIds(found)`: 現在のクロック値から、未発見かつヒント中でない宝のうち
  opacity < `kBlinkVisibleThreshold` の id 集合を返す（通常モードは空集合）。
- `_handleHit` で `findHitTargetId(..., hiddenIds: _hiddenTargetIds(found))`。
- 描画: ターゲットを `_BlinkingTarget`（`AnimatedBuilder` で `Opacity` のみ更新、`child` は
  再構築しない）でラップ。`active = !found && !hinting` のときだけ点滅、それ以外は素通し。

### 4. テスト

- **Unit (`seek_find_logic_test.dart`)**
  - `treasureBlinkOpacity`: 可視区間=1.0 / 消失区間=0.0 / フェードアウト中間=0.5 /
    位相ずらしで「ある宝が消失中でも別の宝は可視」/ `count<=0` ガード。
  - `findHitTargetId`: `hiddenIds` に含む宝は矩形内でも null、空なら従来どおりヒット。
- Widget: 既存 seek_find 画面テストはアニメ起因で skip 運用のため、点滅も純関数＋当たり判定の
  unit で担保（既存方針踏襲）。実機で目視確認。

## 非対象（YAGNI）

- 点滅速度の設定 UI、宝ごとの個別パターン、消失中の薄ゴースト表示（完全消失で十分）。
