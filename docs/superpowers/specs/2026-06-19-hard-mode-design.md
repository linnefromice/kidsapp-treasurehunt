# ハードモード（むずかしい）設計

> 対象: シーク＆ファインドに「ハードモード」を追加する。
> 親要件（ユーザー指示）:
> 1. ハードモードを追加する。
> 2. **全シーンをクリアした後に解放**される。
> 3. **アイコンを少し小さく**し、**探す量を増やす**。

決定済みの設計判断（ユーザー回答）:
- 探す量の増やし方: **既存ダミーを宝に昇格 ＋ 各シーンへハード専用の新ダミー（引っかけ）を追記**。
- アイコンの小ささ: **0.8 倍**（通常表示 1.15 倍の約 7 割サイズ。タブレット横向きでタッチ目標 60dp を概ね維持）。
- 入口: **宝の地図に「ふつう / むずかしい」切替トグル**（全クリア後のみ出現）。

---

## 1. ゴールと非ゴール

**ゴール**
- 全 9 シーンを通常クリアした後、同じスロットで全シーンを「むずかしい」で遊べる。
- むずかしいでは (a) 探す対象が増え（既存ダミー昇格）、(b) 引っかけダミーも残り、(c) アイコンが小さい。
- むずかしいの進捗（クリア状況・発見状態）は通常モードと**完全に独立**。通常クリアは保持される。

**非ゴール**
- 新しいシーン背景・新規シーンの追加（既存 9 シーンを再利用）。
- スター/スコア/タイム等の競争要素（Kids 原則どおり入れない）。
- 失敗ペナルティ・時間制限・ヒント制限の変更（**すべて通常と同一**。むずかしいは「数」と「大きさ」だけを変える）。

## 2. 中核アイデア — シーン定義の純粋変換

新規アセットは作らず、`SceneDef` を変換してハード版を導出する。各シーン JSON に
**ハード専用デコイ**を表す `hardDummies` 配列を追記する（通常モードは読まない）。

```
hardModeSceneDef(base):
  targets  = base.targets ++ base.dummies.map(asTarget)   # 既存ダミーを探す対象へ昇格
  dummies  = base.hardDummies                              # ハード専用の引っかけ
```

- 通常モードは従来どおり `base.targets` / `base.dummies` を使う（**挙動不変**）。
- `asTarget(dummy)` は `FindTarget(id: dummy.id, iconId: dummy.iconId,
  labelKey: 'target.${dummy.iconId}', normalizedRect: dummy.normalizedRect)`。
  - `labelKey` は現状 UI 表示に使われない（CollectionBar は `iconId` で集計）ため合成で十分。
- 図鑑バー（CollectionBar）と当たり判定は既存ロジックをそのまま再利用できる
  （昇格ダミーのアイコン `leaf`/`rabbit`/`anchor` 等は `target_icons.dart` に既存）。

### 整合性の不変条件（最重要）
`scene_consistency_test.dart` の不変条件「ダミーのアイコン ∩ ターゲットのアイコン = 空」を
**ハード版でも**満たす必要がある。ハード版のターゲット集合は
`原targets ∪ 原dummies` なので、`hardDummies` のアイコンは
**そのシーンの原 targets・原 dummies のどれとも重複しない新規アイコン id** を使う。
→ `target_icons.dart` にデコイ用アイコンを追加する。

## 3. アイコンの大きさ

表示と当たり判定は同一スケールを共有する不変条件（`scaledTreasureRect` を render と
hit-test が共用）を維持したまま、スケールを引数化する。

- 通常: `kTreasureDisplayScale = 1.15`（現状維持）。
- ハード: `kHardModeDisplayScale = 0.8`（新規定数）。

`scaledTreasureRect(rect, {scale = kTreasureDisplayScale})` と
`findHitTargetId(..., {scale = kTreasureDisplayScale})` に省略可能 `scale` を追加。
ハード経路だけ `kHardModeDisplayScale` を渡す。display=hit-test の一致は保たれる。

## 4. モードの表現とルーティング

`GameMode { normal, hard }` を新設（拡張余地のため enum）。

- ルート: `/hunt/:sceneId` に任意クエリ `?mode=hard` を付与。
  `state.uri.queryParameters['mode'] == 'hard'` を `GameMode` に解釈。
- `SeekFindScreen({required sceneId, mode = GameMode.normal})`。
- シーン読込は実 id で従来どおり（`sceneProvider(sceneId)`）。読込後にハードなら
  `hardModeSceneDef` で変換する。

### 発見状態の名前空間
発見集合は `foundControllerProvider` を sceneId でキーする。モード間で混ざらないよう、
ハードは `'$sceneId#hard'` をキーにする（通常は `sceneId` のまま）。
`_SceneView` 内で `foundKey` と `displayScale` をモードから導出して使う。

## 5. 進捗の永続化（独立）

`ProgressRepository` にハード用クリア集合を追加（スロット名前空間内）:
- キー: `progress.<slotId>.hardClearedSceneIds`
- API: `hardClearedSceneIds()` / `isHardCleared(id)` / `markHardCleared(id)`
- `clearAll()` はこのキーも削除する（リセット整合）。

`scenes_catalog.dart`:
- `bool allScenesCleared(ProgressRepository p)` = `kSceneCatalog.every((e) => p.isCleared(e.id))`。
- `Future<void> completeHardScene(ProgressRepository p, String id)` = `markHardCleared(id)` のみ
  （ハードは全シーン解放済みなので次解放チェーンは不要）。

## 6. 地図 UI（切替トグル）

`TreasureMapScreen` を `ConsumerStatefulWidget` 化し、ローカル状態 `GameMode _mode` を持つ。

- `allScenesCleared(progress)` が真のときだけ、上部に「ふつう / むずかしい」トグルを表示。
  - キー: `map-mode-toggle`、各ボタン `mode-normal` / `mode-hard`。
  - 全クリア前は従来どおりトグル非表示（`_mode` は常に normal）。
- `_mode == hard` のとき:
  - ノードのクリアバッジ・現在地計算は `isHardCleared` を参照（通常の `isCleared` ではなく）。
  - ノードタップ → `context.go('/hunt/${id}?mode=hard')`。
  - AppBar のカウンタは `hardCleared/total 🏆` を表示。
  - 全ノードは解放済み扱い（タップ可能）。
- 視覚的な手掛かりとして AppBar タイトル等に「むずかしい」を併記（過剰演出はしない）。

完了オーバーレイ（`_ClearOverlay`）は共通のまま。完了処理だけモードで分岐
（`hard ? completeHardScene : completeScene`）。

## 7. 文言（ja/en）

`strings.dart` に追加:
- `home.modeNormal` = 'ふつう' / 'Normal'
- `home.modeHard` = 'むずかしい' / 'Hard'

## 8. 変更ファイル一覧

**新規**
- `lib/features/seek_find/hard_mode.dart` — `GameMode`、`kHardModeDisplayScale`、
  `hardModeSceneDef`、`gameModeFromQuery`。
- `test/unit/hard_mode_test.dart` — 変換・スケールの単体テスト。
- `test/unit/scene_consistency_hard_test.dart`（または既存テスト拡張）— ハード版の不変条件。

**変更**
- `assets/scenes/scene01..09.json` — `hardDummies` 追記（新規アイコン id を使用）。
- `lib/features/seek_find/models/scene_def.dart` — `hardDummies` フィールド + パース。
- `lib/features/seek_find/seek_find_logic.dart` — `scaledTreasureRect`/`findHitTargetId` に `scale`。
- `lib/features/seek_find/target_icons.dart` — デコイ用アイコン/色を追加。
- `lib/features/seek_find/seek_find_screen.dart` — `mode` 受領、ハード変換・`foundKey`・`displayScale`・完了分岐。
- `lib/data/progress_repository.dart` — hardCleared API + `clearAll` 拡張。
- `lib/scenes_catalog.dart` — `allScenesCleared`、`completeHardScene`。
- `lib/router.dart` — `?mode=hard` を解釈し `SeekFindScreen` へ渡す。
- `lib/features/treasure_map/treasure_map_screen.dart` — トグル + ハード表示分岐。
- `lib/shared/strings/strings.dart` — 文言追加。
- `test/unit/scene_def_test.dart` / `test/unit/progress_repository_test.dart` /
  `test/widget/treasure_map_screen_test.dart` / `test/widget/seek_find_screen_test.dart` — 追補。

## 9. テスト戦略（TDD）

- **Unit**
  - `hardModeSceneDef`: 原ダミーが targets に昇格、`dummies == hardDummies`、件数（例 scene01 targets 5→11）。
  - `scaledTreasureRect(scale:)` が任意スケールで中心保持拡縮。
  - `findHitTargetId(scale:)` がハードスケールで見た目どおり判定。
  - `ProgressRepository`: hardCleared が cleared と独立、`clearAll` で両方消える。
  - `allScenesCleared`: 全クリアで true。
  - ハード整合性: 各シーンで `hardDummies` のアイコン ∩ ハードtargets のアイコン = 空、
    id 一意（targets+dummies+hardDummies 通し）、全アイコン既知。
- **Widget**
  - 地図: 全クリア前はトグル非表示 / 全クリア後に出現。むずかしい選択でノードタップが
    `?mode=hard` 遷移、バッジが hardCleared を反映。
  - シーン: ハードで昇格分を含む数のターゲットが描画され、通常より小さい。
- **品質チェック**: `scripts/check.sh`（format → analyze → test）。

## 10. Kids 規制・UX 適合

- 追加 SDK なし（端末ローカル完結のまま）。行動広告/解析/位置情報 SDK 不使用は不変。
- 失敗を罰しない・時間制限なし・無制限ヒントは通常と同一。
- タッチ目標: 0.8 倍でもタブレット横向きで概ね 60dp 以上を維持（第一級対象端末）。
  端末/端の宝で下回り得る点は許容（全クリア後の上級者向け解放のため）。
- 色のみに依存しない・コントラスト基準は既存 UI を踏襲。
