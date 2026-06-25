# 宝アイコン Recraft V4 生成プロンプト集（SVG ベクター）

> kidsapp-treasurehunt の宝/おとりアイコンを Recraft V4 で SVG 量産するための、
> 全 iconId 分のコピペ用プロンプト。`lib/features/seek_find/target_icons.dart` の
> Material アイコン（プレースホルダ）を、絵文字のように多色でリッチな見た目へ差し替える前提。
>
> **ねらい**: 「宝物（金・宝石）っぽい雰囲気」を全体に乗せるのではなく、
> 各題材（りんご・ほし・ねこ…）を *絵文字のようにリッチで多色・つやのある見た目* に揃える。

## Recraft 設定パラメータ（全アイコン共通・固定）

| 項目 | 設定値 | 理由 |
|---|---|---|
| Model | Recraft V4（V4.1 が選べればそちら） | ベクター品質が上 |
| Format | **SVG** | flutter_svg にそのまま乗る・既存 tint/シルエット機構と統合しやすい |
| Output | **1:1（正方形）** | アイコンは正方形必須。4:3 だと余白・中心ズレが出る |
| Mode | PoC=Fast / 本番=Quality（あれば） | 試行は速く、確定後は高品質で |
| Auto Polish | **OFF（最重要）** | ON だと毎回プロンプトが書き換わり、バッチ全体で画風がドリフトする |
| 生成枚数 | 4 | 各題材4案出して最良を選ぶ |
| Style | **Custom Style を作って固定**（下記手順） | 一貫性の本命レバー |

## 一貫性の作り方（Custom Style）

1. **ブートストラップ**: まず `apple / star / heart / cat / gift` を下記フルプロンプト＋上記設定で生成。
2. まとまった 3〜5 枚を選び、Recraft の **Settings → Styles → Create Custom Style**（"Style essentials"）に登録。
3. **本番バッチ**: Style に作った Custom Style を指定し、プロンプトは各 `SUBJECT 句` ＋ `, single centered object` 程度に短縮して残り全 iconId を量産（長い様式記述は Style 側が担う）。
4. 連鎖参照（生成物を次の参照にする）は累積ドリフトの原因。**最初に決めた Custom Style だけ**を参照し続ける。

## 表記ルール

- **完成プロンプト** = `SUBJECT 句` ＋ 下記の **STYLE 接頭辞**（全アイコン共通）。各 iconId の節にはすでに連結済みの全文を載せてある。
- **顔（face）の方針**: 生き物（`duck` / `rabbit` / `bug` / `cat`）のみ friendly face を付与。モノ系は顔なし（`apple` ベースラインに合わせクリーンに）。好みで増減可だが**セット内で統一**すること。
- glyph ではなく **iconId の意味**で生成する（例: `duck` は現状 `flutter_dash` グリフだが、アートは「黄色いアヒル」を作る）。
- `rare_*` の 3 つだけ特別感を出して可（rainbow / jeweled / gold medal）。それ以外は題材本来の色に留め、金色化させない。

### STYLE 接頭辞（共通・固定）

```
single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

---

## 全 iconId プロンプト（計 36 種）

### 宝ターゲット（既存の base ターゲット）

#### `apple`

```
a shiny red apple with a small green leaf, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `duck`

```
a cute yellow baby duck with a friendly face, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `star`

```
a glossy golden five-point star, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `ball`

```
a colorful striped beach ball, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `flower`

```
a bright daisy flower with a yellow center, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `heart`

```
a glossy red heart, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

### おとり（ダミー）アイテム

#### `leaf`

```
a fresh green leaf, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `rabbit`

```
a cute white bunny with a friendly face, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `bug`

```
a friendly red ladybug with a smiling face, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `anchor`

```
a blue ship anchor, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `swimmer`

```
a blue-and-white swim ring float, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `umbrella`

```
a colorful open umbrella, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `car`

```
a cute red toy car, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `key`

```
a golden old-style key, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

### ハードモード専用デコイ

#### `cake`

```
a cute layered birthday cake, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `gift`

```
a wrapped gift box with a ribbon, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `gem`

```
a sparkling blue gem, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `music`

```
a single music note, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `cloud`

```
a fluffy white cloud, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `moon`

```
a calm crescent moon, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `icecream`

```
a soft ice cream cone with two scoops, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `cookie`

```
a chocolate-chip cookie, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `pizza`

```
a cheesy pizza slice, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `bell`

```
a golden hand bell, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `lightbulb`

```
a glowing light bulb, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `cat`

```
a cute round cat head with a friendly face, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `sailboat`

```
a little sailboat on a small wave, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `crown`

```
a cute golden crown, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `fire`

```
a friendly orange flame, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `kite`

```
a colorful diamond kite with a tail, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

### めくり露出（A1）用のかぶせもの

#### `cover_leaves`

```
a small pile of green leaves, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `cover_snow`

```
a rounded mound of white snow, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `cover_box`

```
a closed cardboard box, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

### 低頻度レア宝（C4・特別感OK）

#### `rare_gem`

```
a sparkling rainbow diamond, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `rare_crown`

```
a jeweled royal golden crown, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

#### `rare_medal`

```
a gold medal with a ribbon, single centered object, cute friendly emoji-style icon, flat vector illustration with smooth color gradients and soft simple shading, layered colored shapes, bold saturated candy colors, rounded chunky shapes, clean bold silhouette, high readability at small size, plain background, no text, no border frame, not realistic, no treasure chest, no gold theme
```

---

## 取り込み時の状態（found / unfound）メモ

- 透明背景の SVG として生成 → 図鑑/シーンで **未発見=グレー化（desaturate＋暗め）/ 発見=フルカラー＋グロー** で出し分ける。
- 既存の `UnfoundTreasureIcon`（影絵）と `target_icons.dart` の tint 機構を流用できる。差し替え時は iconId をキーに SVG アセットへマッピングする層を一枚かませる想定。

## 来歴・コンプラ（キッズ規制）

- 生成は有料 tier で行い出力の商用権を確保。存命作家名・商標・既知キャラはプロンプト禁止。
- 各アセットは人手で年齢適切性を審査。事前焼き込みの静的アセットはストアの「ランタイム AI 生成」ポリシー対象外（ランタイム生成を足さない限り）。
- ツール/プラン/プロンプト/人手編集の来歴を記録しておく。
