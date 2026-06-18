# 宝の可視化（A+B）＋ なぞって発見 設計書

- 日付: 2026-06-18
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定（実装計画はこの後 writing-plans で作成）
- 背景: 実機検証で「もりのたからさがし（scene01）で宝が見つからない」と判明。原因は
  **背景がグラデーションのみ・宝が透明領域・図鑑が空白枠**で、何を/どこを探すか視覚情報ゼロだったこと。

---

## 1. 目的とスコープ

実アート投入前でも「遊べる（探して見つかる）」状態にする。
- **A**: 図鑑バーにお題アイコンを表示（何を探すか分かる）。
- **B**: シーンに宝オブジェクトをはっきり描画（どこにあるか見える）。
- **なぞって発見**: タップだけでなく、指/ペンでなぞっても下の宝に反応する。

### スコープ外（別 spec / 別機能）

- 完了画面の「ちずに もどる」ボタン・複数シーン・順次アンロック・シーン別グラデ
  → spec `2026-06-18-multi-scene-unlock-design.md`（#8）の範囲。今回は混ぜない。
- 実イラスト/実アセット、ヒント自動強化、マスコット音声。
- ズーム/パン（本 spec で `InteractiveViewer` を撤去するため当面なし。本格アート時に再検討）。

---

## 2. 決定事項

| 項目 | 決定 |
|---|---|
| 操作 | **タップ + なぞり（ドラッグ/ペン軌跡）**の両方で発見 |
| 拡大/パン | **撤去**（`InteractiveViewer` を外し、シーンを画面にフィット）。なぞりとの競合回避＋小矩形問題の解消 |
| 宝の見え方 | **はっきり表示**（お題アイコンを正解位置に描画）。発見済みは演出を重ねる |
| 図鑑 | 各枠に**お題アイコン**。未発見=グレーのアウトライン / 発見=点灯（amber） |
| アイコン定義 | `target.id → IconData` の共有マップ（図鑑とシーンで同一） |

---

## 3. コンポーネント設計

### 3.1 アイコン対応表（新規・共有）

`lib/features/seek_find/target_icons.dart`:

```dart
import 'package:flutter/material.dart';

/// 宝 id → 表示アイコン（プレースホルダ。実アートで差し替え）。
const Map<String, IconData> _kTargetIcons = {
  'apple': Icons.apple,
  'duck': Icons.flutter_dash,
  'star': Icons.star,
};

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
```

> 図鑑バーとシーン描画の両方がこの関数を使い、見た目を一致させる。今後お題が増えたら
> ここに追記（未定義は `help_outline` にフォールバック）。

### 3.2 図鑑バー（A）

`lib/features/seek_find/widgets/collection_bar.dart` を改修:
- 各枠（`slot.$id`）に `targetIcon(id)` を表示。
- **未発見**: アイコンをグレー（例 `Colors.grey.shade400`）のアウトライン的表示、枠は白。
- **発見**: アイコンを点灯（`Colors.amber.shade800`）、枠を `amber.shade200`。発見アイコンに
  `key: ValueKey('found.$id')` を維持（既存テスト互換）。
- 既存の `targetIds` / `foundIds` インターフェースは維持。

### 3.3 シーン画面（B + 操作 + レイアウト）

`lib/features/seek_find/seek_find_screen.dart` の `_SceneView` を改修:

- **レイアウト**: `InteractiveViewer` を撤去。`LayoutBuilder` で本文領域の `Size` を取得し、
  シーンの `Stack`（`key: const ValueKey('scene-content')`）をその領域いっぱいにする。
  固定 `kSceneSize` 依存を廃止。
- **背景**: 現状のグラデーション（単一）を維持（シーン別配色は別 spec）。
- **宝の描画**: 各 target を `Positioned`（`left/top/width/height = normalizedRect × boxSize`）で
  配置し、`Icon(targetIcon(t.id))` をはっきり描画。発見済みは `FoundBurst` を重ねて点灯感を出す。
- **ジェスチャ**: `GestureDetector` に `onTapDown` / `onPanStart` / `onPanUpdate` を設定し、
  いずれも共通ハンドラ `_handleHit(Offset localPosition, Size sceneSize)` を呼ぶ。
  - `_handleHit` は**最新の発見集合を `ref.read(foundControllerProvider(sceneId))` で取得**し、
    `findHitTargetId(scenePoint: localPosition, sceneSize: sceneSize, targets, foundIds)` で判定。
    未発見ヒット時のみ `markFound` + `playFound`（なぞり中の二重発火・重複音を防止）。
  - 空振りは無反応（罰しない・据え置き）。
- 完了処理（`_handleComplete`）と完了バナーは**変更しない**（本 spec のスコープ外）。

### 3.4 ヒット判定ロジック

`lib/features/seek_find/seek_find_logic.dart` の `findHitTargetId` は**変更なし**
（既に `sceneSize` を引数で受ける）。呼び出し側が固定値の代わりに実描画サイズを渡すだけ。

---

## 4. 操作の期待値（DoD の体験）

1. シーン画面に背景（グラデ）と**宝アイコンが見える**（りんご/とり/ほし）。
2. 宝を**タップ**すると点灯＋キラッ、図鑑の対応枠が点灯。
3. 宝の上を**指/ペンでなぞる**と同様に発見できる（1ストロークで複数を続けて拾える）。
4. 図鑑バーは最初から**お題アイコン（グレー）**を表示し、見つけると点灯する。
5. 空振り（宝以外をタップ/なぞり）は何も起きない。

---

## 5. テスト戦略

| 種別 | 対象 |
|---|---|
| Unit | `targetIcon`（既知 id → 対応アイコン / 未知 → `help_outline`） |
| Widget | `CollectionBar`: 未発見枠にお題アイコン（グレー）表示、発見枠は `found.$id` 点灯。`seek_find_screen`: レスポンシブ化に合わせ `scene-content` の**実サイズ**（`tester.getSize`）+ 原点（`getTopLeft`）でタップ座標を算出して発見できる／**ドラッグ（`tester.drag`/`dragFrom`）で宝の上をなぞって発見**できる／コンプリートで「みつけたね！」（既存）。 |

- `shared_preferences` は `SharedPreferences.setMockInitialValues`、テストは `fvm flutter test`。
- 既存 seek_find テストはアクティブスロット設定済みのまま流用し、座標算出を実サイズ基準へ更新。
- `bash scripts/check.sh` 全緑。

---

## 6. 既存コードへの影響

- `kSceneSize`（`seek_find_screen.dart` の固定 800×600 定数）は**廃止**（`LayoutBuilder` の実サイズに置換）。
  これに依存していた `seek_find_screen_test` の座標算出を実サイズ基準へ更新する。
- `CollectionBar` の API（`targetIds`/`foundIds`）は不変。内部表示のみ変更。
- 既存の発見→図鑑充填→コンプリート→（slot 永続化）の流れは不変。

---

## 7. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| A 図鑑 | 各枠にお題アイコン（未発見グレー / 発見点灯） |
| B シーン | 宝アイコンをはっきり描画（`targetIcon` 共有） |
| 操作 | タップ + なぞり（onTapDown / onPanStart / onPanUpdate） |
| レイアウト | `InteractiveViewer` 撤去 → `LayoutBuilder` でフィット（ズーム当面なし） |
| ヒット判定 | `findHitTargetId` 不変・実描画サイズを渡す |
| スコープ外 | 完了ボタン/複数シーン/シーン別グラデ（#8）、実アート、ヒント、音声 |
