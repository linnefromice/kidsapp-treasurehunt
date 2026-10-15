# 配置のばらつき & テーマ別カバー（箱隠し） 設計

## 要求
- [1] hard を筆頭に宝/ダミーの配置が規則的 → ばらつきを持たせる
- [2] 箱に隠れるパターンの出現率を上げる
- [3] 箱をステージのイメージに合わせる（森=木箱, 空=雲, 海=貝 …）＋ ステージ内でも複数種類

## 現状
- `withShuffledPositions` は**中心座標の集合を入れ替えるだけ**（格子はそのまま）。リプレイ専用。
- カバーは JSON の `cover` フィールドで個別指定。全シーン 2 個/機械的ローテ（leaves→snow→box）でテーマ不一致。
- カバー種は cover_leaves / cover_snow / cover_box の 3 種のみ。

## シーン→テーマ（背景ペインター由来）
01森 02海 03街 04山 05夜 06砂漠 07宇宙 08海中 09雪 10花畑 11虹丘 12城 13銀河

## 設計
### [1] スキャッタ配置（PR B1）
`withShuffledPositions` を「中心入れ替え＋ジッター散布」に拡張:
- 元中心を base に取り（実現可能な非重なり配置を保証）、割当をシャッフル後、各点へ
  半径 r のランダムジッターを付与。[margin,1-margin] でクランプ、既配置との最小距離で
  衝突を弾く（K 回試行、不可なら base を採用）。決定論（渡された Random）。
- 適用範囲: **hard は常時**（first play も）。easy/normal はリプレイ時のみ（first play は作者配置を維持）。

### [2][3] テーマ別カバー（PR B2）
`SceneDef.withThemedCovers(pool, random, rate)` を追加し、ターゲットに pool から
カバーを確率 rate で割当（テーマ一致・複数種から抽選）。**常時適用**（first/replay 両方）で
出現率を底上げ。JSON の authored cover は再割当で上書き（実質無視）。

新カバー資産（ジェネレータで生成）: cover_chest(木箱) / cover_shell(貝) / cover_cloud(雲) /
cover_bush(茂み) / cover_rock(岩) / cover_star(星) / cover_barrel(樽) / cover_flower(花) /
cover_sand(砂山)。既存 cover_leaves/cover_snow/cover_box と合わせ 12 種。

テーマ別 pool（2–3 種）:
- 01森: leaves, bush, chest
- 02海: shell, chest, rock
- 03街: box, barrel, bush
- 04山: rock, bush, chest
- 05夜: cloud, bush, leaves
- 06砂漠: rock, sand, chest
- 07宇宙: cloud, star, rock
- 08海中: shell, rock, bush
- 09雪: snow, box, bush
- 10花畑: flower, leaves, bush
- 11虹丘: cloud, bush, leaves
- 12城: box, barrel, chest
- 13銀河: cloud, star, rock

## 要確認（フォーク）
- Q1 スキャッタ範囲: hard 常時＋他リプレイ（推奨） / 全モード常時 / リプレイのみ
- Q2 カバー率: ~40% / ~55%(推奨) / ~70%
