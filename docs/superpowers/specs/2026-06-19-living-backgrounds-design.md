# 生きた背景（シーン環境アニメーション）設計

**Goal:** シーク＆ファインドの 9 シーン背景に、低振幅・緩やかな環境アニメーション
（漂う雲・舞う光・ホタル・昇る泡・降る雪・星の瞬き）を重ね、静止画だった世界を
「生きている」状態にする。発見体験を邪魔しない“背景の気配”に徹する。

**位置づけ:** ビジュアル改善ガイド 2026 の B 章（生きた背景）・H 章（性能）に対応。
**SDK のみ・アセット不要・追加 package 不要**（`CustomPainter` + `AnimationController`）。

---

## 設計方針（最重要）

`lib/features/seek_find/scene_background.dart` は既に 1251 行で 800 行ガイドを大幅超過。
既存の 9 painter は**シーンの骨格（空・地面・木・建物・山など）**を描く静止画として完成しており、
seek_find のヒット判定・ターゲット配置・既存（スキップ中含む）テストが依存する見た目でもある。

したがって **既存 painter には一切手を入れない**。代わりに：

1. 新ファイル `lib/features/seek_find/scene_ambient.dart` に、**1 つの汎用アニメ層**
   （`_AmbientLayer` + 共有 `_AmbientPainter`）を追加。
2. `sceneBackground(sceneId)` の戻り値を `Stack`（下=既存静止画 / 上=`sceneAmbient(sceneId)`）に
   変更するだけ。静止画レイヤは現状のまま。
3. アニメ層は**新しい粒子セット**を持つ（既存の装飾＝静的な雲/泡/雪/星とは別位置）。
   既存装飾を消さないので二重表示の違和感は出さず、シーンが“より賑わう”方向にのみ作用。

データ駆動（共通化ルール「同形 3 つ以上は汎用化」）: 9 シーン分を 1 つの painter +
シーン別 `AmbientSpec` 設定で表現する。

## 粒子の種類（`AmbientKind`）

| kind | 動き | 用途シーン |
|------|------|-----------|
| `drift` | ふわっと横に流れる雲（端で巻き戻り） | 森・海・山・さばく |
| `mote` | ゆっくり漂う微粒子（sine で上下に揺れる花粉/砂塵） | 森・さばく |
| `firefly` | ゆらゆら漂い alpha が脈動するホタル | 夜の野原 |
| `bubble` | 下から上へ昇る輪（上端で巻き戻り、横に微揺れ） | うみのなか |
| `snow` | 上から下へ降る雪（横に揺れ、下端で巻き戻り） | ゆきやま |
| `twinkle` | その場で alpha が瞬く星 | 夜の街・夜の野原・うちゅう |

## シーン → スペック対応（`ambientSpecsFor`）

1 シーンに複数 kind を重ねられる（`List<AmbientSpec>`）。

| sceneId | スペック |
|---------|---------|
| scene01 森 | drift ×3（白・遅い）+ mote ×8（花粉・淡黄） |
| scene02 海 | drift ×3（白・遅い） |
| scene03 夜の街 | twinkle ×14（白） |
| scene04 山 | drift ×3（白） |
| scene05 夜の野原 | firefly ×7（黄緑発光）+ twinkle ×10 |
| scene06 さばく | drift ×2（淡橙・遅い）+ mote ×6（砂） |
| scene07 うちゅう | twinkle ×18（白）+ drift ×1（星雲ガス・極淡） |
| scene08 うみのなか | bubble ×14（白輪） |
| scene09 ゆきやま | snow ×26（白） |

各粒子の初期位置・サイズ・位相は `math.Random(<sceneSeed>)` で**決定論的**に生成
（`Date.now`/`Math.random` 非依存・再現可能）。動きは `AnimationController` の `t`(0..1 ループ)と
粒子ごとの位相から計算する。

## 構造

- `AmbientKind`（enum）／`AmbientSpec`（`{kind, count, color, speed}` の immutable 設定）
- `List<AmbientSpec> ambientSpecsFor(String sceneId)` — シーン別設定（public・テスト可能）
- `Widget sceneAmbient(String sceneId)` — spec が空なら `SizedBox.shrink()`、あれば `_AmbientLayer`
- `_AmbientLayer`（StatefulWidget, `SingleTickerProviderStateMixin`）
  - 1 本の `AnimationController`（雲は長周期、雪/泡は中周期。代表値 8〜12s を kind 別に内包せず、
    1 本の長周期コントローラ + kind 別係数で表現）`repeat()`
  - `RepaintBoundary` > `AnimatedBuilder` > `CustomPaint(size: …, painter: _AmbientPainter(t, specs))`
- `_AmbientPainter` — spec ごとに粒子を描く。`shouldRepaint => true`（連続値 t）。

## 性能 / Kids 規制（ガイド H 章・README §6）

- 1 シーンの粒子総数は最大でも ~30。`RepaintBoundary` で静止画層と分離（静止画は再描画なし）。
- 低振幅・緩ループ・失敗を罰しない/急かさない背景演出に徹する（点滅は穏やか、原色フラッシュなし）。
- 追加 SDK・ネットワーク・データ収集・アセットなし。端末ローカル描画のみ。
- 当たり判定・ターゲット・既存静止画は不変（このPRでは触らない）。

## テスト戦略

- 追加 unit テスト（`test/unit/scene_ambient_test.dart`）:
  - `ambientSpecsFor` が全 9 sceneId で非空、未知 id で空を返す。
  - 代表マッピング（例: scene08 に `bubble`、scene09 に `snow`、scene03 に `twinkle` が含まれる）。
  - 粒子総数が上限（例: ≤30）以内。
- 追加 widget テスト（`test/widget/scene_ambient_test.dart`）:
  - `sceneBackground('scene01')` 等を `pump()`（`pumpAndSettle` はループのため不可）で描画し
    例外が出ないこと。`_AmbientLayer` が存在すること。未知 id では ambient 無しでも例外が出ないこと。
- 既存テストへの影響なし（hunt 画面の widget テストは既にスキップ。背景はヒット判定に非関与）。

## 変更ファイル

| ファイル | 変更 |
|----------|------|
| `lib/features/seek_find/scene_ambient.dart` | 新規: `AmbientKind`/`AmbientSpec`/`ambientSpecsFor`/`sceneAmbient`/`_AmbientLayer`/`_AmbientPainter` |
| `lib/features/seek_find/scene_background.dart` | `sceneBackground` の戻り値を Stack（静止画 + ambient）に。既存 painter は不変 |
| `test/unit/scene_ambient_test.dart` | 新規 |
| `test/widget/scene_ambient_test.dart` | 新規 |
