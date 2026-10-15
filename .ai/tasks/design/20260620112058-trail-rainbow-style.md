# なぞりトレイル「にじ」スタイル（3色 / フル）実装設計

## 目的

なぞりトレイルのキラキラ色に「にじ（虹）」スタイルを追加する。
単色 6 色に加えて **にじ3色**（選んだ 3 色を循環）と **にじフル**（色相を一周）を選べる。

## ユーザー決定

- にじは「3色」と「フル」を選べる。
- 3色の選択 UI は **ドロップダウン 3 つ**（セレクト形式）。位置 1/2/3 をそれぞれ 6 色から選ぶ。
- 3色は **同じ色の重複 OK**（バリデーションなし）。

## モデル（`lib/features/seek_find/models/trail_color.dart`）

- `TrailColorChoice`（既存 6 色 enum）はそのまま「色の部品」として残す。
- 追加 `TrailStyle` enum: `solid` / `rainbow3` / `rainbowFull`。`id`・`fromId`・`fallback = solid`。
- 追加 `TrailSetting`（不変値オブジェクト）:
  - `TrailStyle style`
  - `TrailColorChoice solidColor`（単色時の色）
  - `List<TrailColorChoice> threeColors`（常に長さ 3）
  - `copyWith` / `==` / `hashCode`
  - `static TrailSetting fromPersisted({String? styleId, String? solidId, String? colors3Csv})`
    - csv を `,` 分割 → `fromId` → 先頭 3 件、足りなければ既定（sky,pink,yellow）でパディング。常に長さ 3。
  - `static const defaultThreeColors = [sky, pink, yellow]`
- `resolveTrailColor(TrailSetting setting, {required int particleIndex})` を新シグネチャに変更:
  - `solid` → `solidColor.baseColor`
  - `rainbow3` → `threeColors[particleIndex % 3].baseColor`
  - `rainbowFull` → `_rainbowHue(particleIndex)` = `HSVColor.fromAHSV(1, (i * 40) % 360, 0.9, 1.0).toColor()`

## 永続化（`lib/data/settings_repository.dart`・全スロット共通・後方互換）

- 既存 `settings.trailColor`（単色 id, 既定 `sky`）は**そのまま**。
- 追加 `settings.trailStyle`（既定 `solid`）: `trailStyleId()` / `setTrailStyleId`。
- 追加 `settings.trailColors3`（CSV, 既定 `sky,pink,yellow`）: `trailColors3Csv()` / `setTrailColors3Csv`。
- data 層は features に依存しない。既定値はリテラル文字列。解釈は model の `fromPersisted` が担う。

## プロバイダ（`lib/providers.dart`）

- `TrailColorController` → `TrailSettingController extends Notifier<TrailSetting>` に置換。
  - `build()`: repo の styleId / trailColorId / colors3Csv を `TrailSetting.fromPersisted` に渡す。
  - `selectStyle(TrailStyle)` / `selectSolid(TrailColorChoice)` / `selectThreeColorAt(int index, TrailColorChoice)`。
    各々 repo へ保存し state 更新。
- `trailColorControllerProvider` → `trailSettingControllerProvider`。

## 設定画面（`lib/features/settings/settings_screen.dart`）

「なぞった ときの いろ」セクション:
1. スタイル ChoiceChip 群（`TrailStyle.values`）: 単色 / にじ3色 / にじフル。
2. サブフォーム（選択スタイルに応じて 1 つだけ表示）:
   - `solid` → 既存 6 色 ChoiceChip（`selectSolid`）。
   - `rainbow3` → 「3つ えらぶ」+ `DropdownButton<TrailColorChoice>` × 3（`selectThreeColorAt`）。各項目 = スウォッチ + 名前。`itemHeight ≥ 60`、フィールドは最小 60dp。
   - `rainbowFull` → 短い説明テキスト（追加設定なし）。
- 共通スウォッチ（円 + フチ）を `_ColorSwatch` として抽出（ChoiceChip avatar / Dropdown item / 既存単色チップで 3+ 箇所利用 → component-reuse ルール）。

## シーン（`lib/features/seek_find/seek_find_screen.dart`）

- `_handlePanTrail`: `ref.read(trailSettingControllerProvider)` → `resolveTrailColor(setting, particleIndex: _trailSeq)`。
- 粒を撒くループ・しきい値・上限は不変。

## i18n（`lib/shared/strings/strings.dart`） ja/en

- `trailStyle.solid` = たんしょく / Solid
- `trailStyle.rainbow3` = にじ（3しょく）/ Rainbow (3)
- `trailStyle.rainbowFull` = にじ（フル）/ Rainbow (full)
- `trailColor.pick3` = 3つ えらぶ / Pick 3 colours
- `trailColor.slot1/slot2/slot3` = 1つめ/2つめ/3つめ / 1st/2nd/3rd
- `trailStyle.rainbowFull.hint` = なぞると にじいろ / Cycles through the rainbow

## テスト

- Unit `trail_color_test`: TrailStyle.fromId/fallback; TrailSetting.fromPersisted（正常/壊れ csv パディング/未知 style→solid）; resolveTrailColor（solid / rainbow3 の % 3 循環 / rainbowFull が index で変化し決定的）。
- Unit `settings_repository_test`: trailStyle 既定 `solid`・trailColors3 既定 `sky,pink,yellow`・永続化。
- Widget `settings_screen_test`: スタイル 3 チップ描画 / にじ3色でドロップダウン 3 つ出現・にじフルで消える・単色で 6 チップ / ドロップダウン変更で csv 永続化・反映 / スタイル選択で永続化。

## ドキュメント

- `docs/glossary.md`: Trail Style / にじ3色・にじフル 用語追記。
- `docs/development.md`: 設定 DoD にスタイル選択を追記。

## 規制

行動広告・データ収集・位置情報いずれも無し。効果音/演出のローカル完結。
