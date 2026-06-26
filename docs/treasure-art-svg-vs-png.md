# 宝アート: SVG か PNG か（検討記録）

> 結論: **小さく多数の一覧アイコンは SVG / 大きく少数の“山場”は PNG** のハイブリッドが最適。
> 切替軸は「サイズ × 枚数」。本リポジトリは `TreasureGlyph` に描画を一元化しており、
> アイコン単位で段階的に PNG へ“格上げ”できる。

## 背景
- 現状の宝/おとり/バッジは **手書き SVG**（generator 生成・v4 スタイル）。
- 質問: リッチさを上げるなら PNG の方が良いか？

## 小さく多数の一覧アイコン → SVG が向く
- 拡大縮小で破綻しない（おとり scale 0.4–1.6 / 広域キャンバス拡大 / 発見バースト変形）。
- 軽い（各 1–2KB。宝80+＋バッジ10 でも合計わずか）。
- 無料・無制限・完全一貫・即イテレート（generator 1 箇所で全再生成）。
- 再着色できる（発見グロー/ヒントは `targetColor` で別に発光）。

## SVG の“リッチさの天井” → ここは PNG が勝つ
- 本物の 3D 艶・やわらかい影・絵画的ディテールは手書き SVG では再現困難。
- `flutter_svg` は `feGaussianBlur` 等フィルタ非対応 → グローは図形＋グラデで“偽装”。
- 超えるには AI 生成 PNG（Gemini/OpenAI）や Blender 3D 書き出しが必要。

## このアプリの最適解＝ハイブリッド
PNG の richness が最も効くのは「大きく・主役で・少数」:
- レア発見のリビール（中央に 画面短辺×0.36 で巨大表示）
- バッチ取得の祝福 / 図鑑の大きく見る表示
- 背景・ホームの装飾アート
これらだけ高解像度 PNG に差し替え、ゲーム中の小さな多数アイコンは SVG 継続。

## 実装メカニズム（PNG 優先の差し込み口）
- `treasurePngAsset(id)` = `assets/treasure_icons_hd/<id>.png`。
- `kHeroPngIcons`（Set）に登録した id だけ、`TreasureGlyph(found:true)` が **PNG 優先**で描画。
  未登録は従来どおり SVG。未発見シルエットは SVG のまま（PNG ヒーローも SVG を残す）。
- ドリフトテスト `treasure_hero_png_test` が登録 id の PNG 実在を検証。

### ヒーロー PNG の足し方（2 ステップ）
1. `assets/treasure_icons_hd/<id>.png` を置く（透明背景・正方形・1024px 目安）。
   - `id` は既存の宝/バッジ iconId に一致させる（例 `rare_gem`）。
2. `target_icons.dart` の `kHeroPngIcons` に `<id>` を足す。
→ コード変更はこれだけ。`TreasureGlyph` を使う全箇所（シーン内・図鑑・レアリビール）で自動的に PNG 表示に切替わる。

## 現状の初期ヒーロー枠
- `rare_gem` / `rare_crown` / `rare_medal`（レア3種）を登録済み。
- ただし**現物は SVG を高解像度ラスタライズしたスタンドイン**（richness は SVG と同等）。
  本番の艶を出すには Gemini/OpenAI の AI アートや 3D 書き出し PNG で上書きすること。
