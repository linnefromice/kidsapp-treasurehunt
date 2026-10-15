# 「街／暮らし」系ステージ 追加候補の検討

## 前提
- 現在 17 ステージ（自然13＋暮らし系4: まち/おかし/どうぶつえん/ゆうえんち）。
- 各シーン = 専用背景ペインター + 環境アニメ + テーマ別アイコン（targets 8 / decoys 8、非交差）。
- 既存アイコン: 83種（cover 除く）。新規は Python ジェネレータ（v4 スタイル）で決定論生成可能。
- ユーザー要望: 「街のような観点」＋「一部シチュエーションにフォーカスした」マップ。

## 評価軸
- ✅ 既存アイコンだけで即実装可（新規アセット 0）
- ⚠️ 数個の新アイコン生成が必要（ジェネレータで対応可）
- 🔴 医療・文具など専用アイコン多数が必要（コスト大）

---

## Tier A ── いますぐ作れる（新規アセット 0）

### A1. みなと（Harbor / 港町）⚓ ✅
ボートと桟橋の港町。海(02)/海中(08)とは「人の営み（船・港）」で差別化。
- targets: sailboat, anchor, fish, crab, shell, seahorse, octopus, bucket
- decoys: bird, cloud, sun, flag, starfish, jellyfish, umbrella, gem
- 背景: 桟橋・停泊船・灯台・水面。

### A2. こうえん（Neighborhood Park / 近所の公園）🛝 ✅
遊具とピクニック。花畑(10)/遊園地(17)とは「近所の日常」で差別化。
- targets: ball, kite, balloon, umbrella, backpack, gift, music, flag
- decoys: bird, butterfly, bee, flower, sunflower, leaf, cat, cloud
- 背景: 芝生・ベンチ・すべり台/ブランコの影・池。

### A3. こどもべや（Toy Room / おもちゃ部屋）🧸 ✅【フォーカス型・室内】
屋外でなく「部屋の中」を探す、寄りのシチュエーション。
- targets: ball, balloon, car, kite, gift, backpack, music, bell
- decoys: cat, star, heart, lightbulb, key, cloud, flower, crown
- 背景: ラグ・棚・窓・おもちゃ箱。

### A4. いなか（Countryside Farm / いなかの のうじょう）🚜 ✅
畑と納屋。動物園(16)とは「農村の暮らし」で差別化。
- targets: duck, rabbit, apple, acorn, mushroom, sunflower, bucket, house
- decoys: bird, bee, butterfly, cat, leaf, flower, cloud, sun
- 背景: 畑の畝・納屋・柵・丘。

### A5. なつまつり（Summer Festival / 夏祭り）🎆 ✅【フォーカス型・イベント】
夜店と提灯。フォーカス型の季節イベント。
- targets: balloon, kite, fish（金魚すくい）, music, gift, flag, star, fire（提灯）
- decoys: bell, heart, sun, moon, cloud, bug, firefly, umbrella
- 背景: 夜の屋台・提灯の列・ちょうちん灯り。

### A6. まちのおしごと（Town Helpers / はたらくまち）🚒 ✅
消防・警察・信号など「まちのおしごと」。scene14まちの働く車バージョン。
- targets: car, bus, trafficlight, fire, shield, key, flag, bell
- decoys: house, cloud, sun, balloon, lightbulb, bird, umbrella, gift
- 背景: 消防署/交番のファサード・道路。

---

## Tier B ── 数個の新アイコンが必要（ジェネレータで対応可・高価値）

### B1. スーパー／おかいもの（Supermarket）🛒 ⚠️【最有力の「街」シチュエーション】
最も「街の暮らし」らしい。カゴを持って食材を探す。
- 既存で使える: apple, cookie, cake, pizza, icecream, fish
- 新規が欲しい: banana, bread, milk, carrot, egg, （basket/cart）→ 4〜6種
- 背景: 陳列棚・値札・カート。

### B2. きょうしつ／がっこう（Classroom）✏️ ⚠️
- 既存: backpack, apple, bell, ball, music, star, crown, kite
- 新規が欲しい: pencil, book, notebook, clock, scissors → 3〜5種
- 背景: 黒板・机・窓。

### B3. だいどころ（Kitchen）🍳 ⚠️【フォーカス型・室内】
- 既存: cake, cookie, pizza, apple, icecream, fish
- 新規が欲しい: pot, cup, spoon, kettle, plate → 4〜5種
- 背景: コンロ・棚・シンク。

### B4. えき／でんしゃ（Train Station）🚉 ⚠️
- 既存: bus, car, trafficlight, flag, key, clock(無)
- 新規が欲しい: train, ticket, clock, bench, signal → 4〜5種
- 背景: ホーム・線路・時計。

---

## Tier C ── コスト大（今は非推奨）
- びょういん（Hospital）🔴 医療アイコン多数
- としょかん/ほんや（Library）🔴 本など
- こうじげんば（Construction）🔴 重機・工具

---

## 推奨
1. **まず Tier A から 3〜4 本**（新規アセット 0 で確実・速い）。特に街系の
   **A6 まちのおしごと / A1 みなと / A3 こどもべや（室内フォーカス）**。
2. 次に **B1 スーパー**（最も「街の暮らし」らしく高価値）。食材アイコンを
   ジェネレータで 4〜6種追加してから実装。
3. B2 きょうしつ / B3 だいどころ は、新アイコンを一括生成すれば同時に狙える。

## 未確定（ユーザー確認）
- どの候補を、何本、どの順で実装するか。
- Tier B に進む場合、新アイコン生成を許可するか（ジェネレータ拡張）。
