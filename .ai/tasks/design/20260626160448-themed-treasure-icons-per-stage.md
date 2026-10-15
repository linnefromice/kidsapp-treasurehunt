# ステージ別テーマ宝/ダミー＆新規SVGアイコン 設計

## 要求
宝/ダミーのパターンをステージの特徴に合わせる。[1]プロンプト/設計→[2]SVG→[3]組込 の流れで多数のアイコンを追加。

## 現状
- targets = 汎用6種(apple/duck/star/ball/flower/heart)の使い回し。ダミーは全アイコンのスライディングウィンドウ。テーマ無関係。
- 図鑑カタログは collectionCatalogProvider が各シーンの targets.iconId から自動生成。→ targets をテーマ別にすれば図鑑も自動でワールド別に特徴化。
- カテゴリ(なかま別D4): animal/food/shape/toy/nature。
- C2おとり再抽選 = グローバル kDecoyIconPool。
- 汎用6種ハードコード: scene_variety_test / collection_catalog_test / collection_logic_test 等（追従更新）。

## テーマ別 宝(各5・🔁既存/✨新規) ※カテゴリ
- 01森: mushroom✨nature, acorn✨nature, fox✨animal, owl✨animal, butterfly✨animal
- 02海: starfish✨animal, crab✨animal, shell✨nature, sailboat🔁toy, bucket✨toy
- 03街: car🔁toy, balloon✨toy, trafficlight✨shape, house✨shape, bus✨toy
- 04山: pinetree✨nature, squirrel✨animal, hedgehog✨animal, backpack✨toy, bird✨animal
- 05夜: moon🔁shape, star🔁shape, owl🔁animal, firefly✨animal, comet✨shape
- 06砂漠: cactus✨nature, camel✨animal, sun✨nature, snake✨animal, pyramid✨shape
- 07宇宙: rocket✨toy, planet✨shape, ufo✨toy, astronaut✨animal, comet🔁shape
- 08海中: fish✨animal, octopus✨animal, seahorse✨animal, jellyfish✨animal, shell🔁nature
- 09雪: snowman✨nature, snowflake✨shape, mitten✨toy, penguin✨animal, sled✨toy
- 10花畑: flower🔁nature, butterfly🔁animal, bee✨animal, bug🔁animal, sunflower✨nature
- 11虹丘: rainbow✨shape, cloud🔁nature, balloon🔁toy, kite🔁toy, sun🔁nature
- 12城: crown🔁shape, key🔁toy, gem🔁shape, shield✨toy, flag✨shape
- 13銀河: star🔁shape, planet🔁shape, saturn✨shape, comet🔁shape, galaxy✨shape

## 新規アイコン(約45) — 生成バッチ
animal: fox, owl, butterfly, bird, squirrel, hedgehog, crab, starfish, fish, octopus, seahorse, jellyfish, penguin, camel, snake, bee, astronaut(人物だがanimal枠)
nature: mushroom, acorn, shell, pinetree, cactus, sun, snowman, sunflower
shape: trafficlight, house, comet, pyramid, planet, snowflake, rainbow, flag, saturn, galaxy
toy: bucket, balloon, bus, backpack, rocket, ufo, mitten, sled, shield

## ダミー方針
各ステージのダミープール = そのテーマ宝の近縁＋関連既存（色/種類違い）。C2 をシーン別プール(scene_decoys.dart)へ。

## [3] 構造変更
1. 13 シーンJSON 書き換え（themed targets/dummies/hardDummies）
2. target_icons: 新規45の IconData/Color
3. treasure_category: 新規のカテゴリ登録
4. C2: withReseededDecoyIcons をシーン別プール参照に
5. テスト更新（汎用6種前提）＋ drift test が新SVG実在を自動検証
6. 図鑑カタログ/カテゴリビューは自動追従（要 expectations 更新）

## 進め方の選択肢
- 全13ステージ一括 / 代表数ステージ先行(パイプライン検証)→残り
- 宝は完全テーマ別 / 一部に汎用を残す
