# 可変ダミーサイズ（Normal / Hard）設計メモ

## 目的

Normal / Hard の探索難易度を上げる演出として、**おとり（デコイ）のアイコンサイズを
ものによって変える**（小さい紛れ物・大きい紛れ物が混在）。宝(target)のサイズは不変。

## 決定事項（ユーザー確認済み）

- スコープ = **A: ダミーのみ可変**（宝は据え置き）。
- 対象モード = **Normal と Hard 両方**（= `hardDummies` が描画される全モード）。Easy は不変。
- 方式 = **データ駆動**。`DummyItem` に per-item の `scale`（既定 1.0）を持たせ、
  単一の `scaledTreasureRect` に倍率を1つ通すだけ。モード分岐は入れない。

## なぜ保守性が崩れないか

- サイズの出所は今も昔も `scaledTreasureRect` **1関数**。描画(`_positioned`)も
  当たり判定(`findHitTargetId`)もこの同じ関数を呼ぶため「見えている＝押せる」が自動で保たれる。
- デコイは**ヒット判定の対象外**（`findHitTargetId` は `scene.targets` のみ走査）。
  よってデコイの `scale` は描画にしか影響せず、当たり判定の不変条件に一切触れない。
- デコイはタップ対象でないため **60dp タッチ下限の制約も無い**（宝なら必要だが今回は対象外）。

## 変更点

1. `DummyItem` に `final double scale`（既定 1.0）。JSON 任意フィールド `scale`。
2. `scaledTreasureRect(Rect, {double itemScale = 1.0})` に倍率を追加し、
   `width/height *= kTreasureDisplayScale * itemScale`。既定 1.0 で従来挙動と一致（回帰なし）。
3. `seek_find_screen.dart` のデコイ描画ループで `itemScale: d.scale` を渡す。
   宝の描画・判定は `itemScale` 既定（1.0）のまま＝完全不変。
4. 9 シーンの `hardDummies` に `scale` のばらつきを付与（小さめ/大きめを混在）。

## テスト

- `DummyItem.fromJson`: `scale` あり→値 / なし→1.0。
- `scaledTreasureRect`: `itemScale` 既定で従来値 / 明示倍率で乗算。
- 既存の当たり判定テストは不変（宝の経路を変えないため回帰しないことを確認）。
