# アドベンチャーマップ + 複数シーン順次アンロック 設計書

- 日付: 2026-06-18
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定（実装計画はこの後 writing-plans で作成）
- 関連: `docs/superpowers/specs/2026-06-17-multi-scene-unlock-design.md`（#8）を**本 spec が取り込み・置換**する
- 根拠: 調査レポート（D: ステージ/アンロック・進捗可視化・マスコット, F: ゴール勾配=「あと少し」, 検証: クラフト感）

---

## 1. 目的とスコープ

ホーム「宝の地図」を **アドベンチャーマップ**（蛇行する道に沿ったステージノード）に刷新し、
同時に **複数シーンの順次アンロック**を実装する。クリアで次が開き、道が伸び、進行が一目で分かる。

実装は**純 Flutter・アート不要**（プレースホルダ）。実イラストは後で差し替え。

### 含む
- 順次アンロック（クリア → 次シーン解放）、`scene02`/`scene03` データ
- シーン完了画面の「ちずに もどる」ボタン、シーン別背景グラデ
- アドベンチャーマップ（蛇行パス・ノード状態・「いま!」脈動・進捗ヘッダー・テーマアイコン）

### スコープ外（YAGNI）
- 実シーン/マップのイラスト（背景はプレースホルダ）
- マスコットのマップ配置、スター/スコア、4 シーン以上、スクロールするマップ
- ズーム/パン（現状どおり無し）

---

## 2. 決定事項

| 項目 | 決定 |
|---|---|
| 進行 | 順次アンロック（クリア N → N+1 解放）。最後は no-op（全クリア） |
| シーン数/お題 | 3（`scene01`=3 / `scene02`=4 / `scene03`=5） |
| マップ要素 | 蛇行パス（点線）/ ノード状態アイコン / 「いま!」脈動 / 進捗ヘッダー / テーマアイコン |
| ノード配置 | カタログにキュレートした正規化座標 |
| 背景 | プレースホルダ（暖色グラデ）。実アート後差し替え |
| 進捗ヘッダー | 「クリア n/3 🏆」（`clearedSceneIds` ベース） |

---

## 3. 進行ロジック（#8 取り込み）

### 3.1 カタログ拡張 `lib/scenes_catalog.dart`

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class SceneCatalogEntry {
  const SceneCatalogEntry(this.id, this.titleKey, this.mapPos, this.themeIcon);
  final String id;
  final String titleKey;
  final Offset mapPos;      // 0.0–1.0 正規化（マップ上の位置）
  final IconData themeIcon; // 森/海/空
}

const String kFirstSceneId = 'scene01';

const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry('scene01', 'scene.scene01.title', Offset(0.20, 0.32), Icons.park),
  SceneCatalogEntry('scene02', 'scene.scene02.title', Offset(0.52, 0.60), Icons.water),
  SceneCatalogEntry('scene03', 'scene.scene03.title', Offset(0.82, 0.30), Icons.cloud),
];

/// kSceneCatalog の並び順で次のシーン id。最後なら null。
String? nextSceneId(String id) {
  final i = kSceneCatalog.indexWhere((e) => e.id == id);
  if (i < 0 || i + 1 >= kSceneCatalog.length) return null;
  return kSceneCatalog[i + 1].id;
}
```

### 3.2 クリア時の「完了処理」（テスト可能な純関数）

`lib/scenes_catalog.dart` に追加（`ProgressRepository` を受け取り、catalog を知る側に置く）:

```dart
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

Future<void> completeScene(ProgressRepository progress, String sceneId) async {
  await progress.markCleared(sceneId);
  final next = nextSceneId(sceneId);
  if (next != null) {
    await progress.unlock(next);
  }
}
```

`seek_find_screen` の `_handleComplete` をこれに置換:
```dart
Future<void> _handleComplete(String sceneId) async {
  await completeScene(ref.read(progressRepositoryProvider), sceneId);
  await ref.read(audioServiceProvider).playComplete();
  if (mounted) setState(() => _completed = true);
}
```
> アクティブスロットにスコープされるため進行は**スロットごとに独立**。

### 3.3 シーンデータ・文字列・アイコン

- `assets/scenes/scene02.json`（4 お題）/ `scene03.json`（5 お題）を追加（既存 `scene01.json` と同形式）。
- お題は既存 `apple`/`duck`/`star` に加え数種（`ball`/`flower`/`heart` 等）を使用。
  - `lib/features/seek_find/target_icons.dart` にアイコン追記（例 `ball`→`Icons.sports_soccer`,
    `flower`→`Icons.local_florist`, `heart`→`Icons.favorite`）。
  - `lib/shared/strings/strings.dart` に `target.ball`/`target.flower`/`target.heart` を ja/en で追記。
- `seek.toMap`（ja「ちずに もどる」/ en「Back to map」）を strings に追記。

### 3.4 シーン画面の追加（小）

- 背景グラデをシーン別に（`seek_find_screen` 内のマップ）: scene01=緑系 / scene02=青系 / scene03=空色系。
- 完了表示に **`KidsButton`「ちずに もどる」** を追加（`context.go('/')`）。既存の完了バナーに併記。

---

## 4. アドベンチャーマップ（ホーム刷新）

`lib/features/treasure_map/treasure_map_screen.dart` を全面刷新（GridView を撤去）。

### 4.1 構成

- `Scaffold` AppBar: タイトル `home.title` + 設定 `IconButton`（`/settings`）。
  AppBar 下またはタイトル横に **進捗ヘッダー**「クリア n/3 🏆」（`clearedSceneIds.length`/`kSceneCatalog.length`）。
- 本文: `LayoutBuilder` → `Stack(fit: StackFit.expand)`:
  1. **背景**: 暖色グラデの `DecoratedBox`（プレースホルダ）。
  2. **蛇行パス**: `CustomPaint`（`_TrailPainter`）。隣接ノード中心（`mapPos × size`）を点線で結ぶ。
     区間は「始点ノードがクリア済みなら色付き、未クリアなら薄色」。
  3. **ノード**: `kSceneCatalog` 各要素を `Positioned`（中心を `mapPos × size` に）で配置。
     `key: ValueKey('scene-node.$id')`。

### 4.2 ノード状態（`_MapNode`）

- 共通: 円形メダリオン + `themeIcon`、下にタイトル（`tr`）。
- **クリア済み**（`isCleared`）: 旗/チェックのバッジ、明色。`key: ValueKey('node-cleared.$id')`。
- **解放・未クリア**（`isUnlocked && !isCleared`）: **脈動アニメ（`AnimationController.repeat(reverse:true)` の scale）** で「いま!」。`key: ValueKey('node-current.$id')`。
- **ロック**（`!isUnlocked`）: 南京錠 + 色あせ、`key: ValueKey('node-locked.$id')`。
- タップ: 解放済み → `context.go('/hunt/$id')`、ロック → 無反応。

### 4.3 データ参照

既存どおり `ref.watch(progressRepositoryProvider)`（アクティブスロットにスコープ）で
`isUnlocked`/`isCleared` を参照。`go_router`/`localeControllerProvider` も既存利用。**API 追加なし**。

---

## 5. テスト戦略

| 種別 | 対象 |
|---|---|
| Unit | `nextSceneId`（順送り/末尾 null/未知 null）。`completeScene`（クリア + 次解放 / 末尾は no-op / スロット独立）。`SceneDef.loadAsset` が `scene01/02/03` を読める（targets 非空）。`targetIcon` 追加分。`strings` 追加分。 |
| Widget | ホーム: ノード3つ表示、状態キー（`node-cleared`/`node-current`/`node-locked`）が進捗に応じて出る、進捗ヘッダー表示。**`pumpAndSettle` は使わない**（「いま!」脈動は repeating のためハングする）— `pump()` のみで初期フレームを検証。 |

- `seek_find_screen` の widget テストは引き続き skip（既存方針）。完了→次解放のロジックは
  `completeScene` の unit で担保。
- `shared_preferences` は `setMockInitialValues`。全体 `bash scripts/check.sh` 緑。

> **注意（既存の教訓）**: repeating アニメ（脈動）がある画面の widget テストで `pumpAndSettle()` を
> 呼ぶと永久に settle せずハングする。ホームのテストは `pump()` のみを使う。

---

## 6. 完成定義（DoD）

1. ホームが地図表示（背景 + 蛇行パス + 3ノード）。`scene01` は「いま!」で脈動、他はロック。
2. `scene01` クリア → ホームで `scene02` が解放（パスが scene01→scene02 区間で色付き、scene02 が脈動）。
3. `scene02`→`scene03` も同様。`scene03` クリアで全クリア（エラーなし）。
4. 進捗ヘッダーが「クリア n/3」で増える。
5. 各シーンは背景色が異なり、お題数（3/4/5）が異なる。完了画面に「ちずに もどる」。
6. 進行はセーブスロットごとに独立。

---

## 7. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| 進行 | `completeScene`（markCleared + unlock(next)）。catalog に `nextSceneId` |
| データ | scene02/03 json、target アイコン/ラベル追加、`seek.toMap` |
| ホーム | アドベンチャーマップ（CustomPainter パス + 状態ノード + 脈動 + 進捗ヘッダー + テーマアイコン） |
| 配置/背景 | カタログのキュレート座標 / プレースホルダ暖色グラデ |
| テスト | ロジックは unit（`completeScene` 等）、ホームは pump() のみの widget、seek_find は skip 継続 |
