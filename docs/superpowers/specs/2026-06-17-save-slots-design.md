# セーブスロット（3スロット）設計書

- 日付: 2026-06-17
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定（実装計画はこの後 writing-plans で作成）
- 前提: シーク＆ファインド MVP 実装済み（`docs/superpowers/specs/2026-06-17-treasure-hunt-skeleton-design.md`）

---

## 1. 目的とスコープ

子供（兄弟など複数人）が**それぞれ独立した進捗**で遊べるよう、**3 つのセーブスロット**を導入する。
起動時にスロット選択画面を出し、固定アバターで識別する。各スロットはリセット（やり直し）でき、
リセットは保護者ゲートの後に実行する。

### スコープ外（YAGNI）

- スロットの**名前入力・アバター選択**（アバターは各スロット固定の 3 種）
- スロットごとの言語設定（言語は**全スロット共通＝端末設定**のまま）
- 4 つ以上の可変スロット / スロットのコピー・並べ替え
- 旧データ移行（本アプリは未リリースのため不要）

---

## 2. 決定事項

| 項目 | 決定 |
|---|---|
| スロット数 | 固定 3 |
| スロットが分離するデータ | **進捗のみ**（解放済み/クリア済みシーン）。言語は全スロット共通 |
| 識別 | 各スロット固定のアバターアイコン（名前入力・選択なし） |
| 起動時 | **スロット選択画面**（`/slots`）。最後のスロットの自動再開はしない |
| リセット | あり。**保護者ゲート（算数問題 stub）→ リセット** |
| 永続化 | shared_preferences のキーをスロットで名前空間化（バックエンド無し継続） |

---

## 3. データモデルと永続化

### 3.1 スロット定義（静的カタログ）

`lib/save_slots_catalog.dart`:

```dart
class SaveSlot {
  const SaveSlot(this.id, this.avatar);
  final String id;        // 'slot1' | 'slot2' | 'slot3'
  final IconData avatar;  // 固定アバター（実画像は後で差し替え）
}

const List<SaveSlot> kSaveSlots = [
  SaveSlot('slot1', Icons.pets),          // 例: いぬ
  SaveSlot('slot2', Icons.cruelty_free),  // 例: うさぎ
  SaveSlot('slot3', Icons.flutter_dash),  // 例: とり
];
```

### 3.2 永続化キー

| キー | 型 | 意味 |
|---|---|---|
| `save.createdSlotIds` | StringList | 「開始済み（作成済み）」スロット id の集合 |
| `progress.<slotId>.unlockedSceneIds` | StringList | そのスロットの解放済みシーン |
| `progress.<slotId>.clearedSceneIds` | StringList | そのスロットのクリア済みシーン |
| `settings.locale` | String | 言語（**全スロット共通・据え置き**） |

> 旧キー `progress.unlockedSceneIds` / `progress.clearedSceneIds` は廃止し、スロット名前空間付きに置換。
> 未リリースのため移行処理は実装しない。

### 3.3 Repository

- **`ProgressRepository(SharedPreferences prefs, String slotId)`**（スロットスコープ化）
  - キー: `progress.$slotId.unlockedSceneIds` / `progress.$slotId.clearedSceneIds`
  - メソッド: `unlockedSceneIds()` / `clearedSceneIds()` / `isUnlocked(id)` / `isCleared(id)` /
    `ensureInitialUnlock(firstSceneId)` / `unlock(id)` / `markCleared(id)` / **`clearAll()`**（当該スロットの両キーを削除）
- **`SaveSlotRepository(SharedPreferences prefs)`**（新規）
  - キー: `save.createdSlotIds`
  - メソッド: `createdSlotIds()` / `isCreated(slotId)` / `markCreated(slotId)` / `removeCreated(slotId)`

---

## 4. 状態管理（Riverpod・手動）

`lib/providers.dart` に追加/変更:

- `saveSlotRepositoryProvider`（`Provider<SaveSlotRepository>`）
- `activeSlotProvider`（`NotifierProvider<ActiveSlotController, String?>`、初期 `null`）
  - `select(String slotId)` で state を設定（選択中スロット）
- **`saveSlotControllerProvider`**（`NotifierProvider<SaveSlotController, Set<String>>`）—
  状態は「作成済みスロット id 集合」。選択画面はこれを購読して作成済み/未作成を判定。
  - `build()` → `saveSlotRepository.createdSlotIds().toSet()`
  - `createSlot(slotId)`:
    1. `saveSlotRepository.markCreated(slotId)`
    2. `ProgressRepository(prefs, slotId).ensureInitialUnlock(kFirstSceneId)`
    3. `state = {...state, slotId}`
  - `resetSlot(slotId)`:
    1. `saveSlotRepository.removeCreated(slotId)`
    2. `ProgressRepository(prefs, slotId).clearAll()`
    3. `state = state.where((e) => e != slotId).toSet()`
- `progressRepositoryProvider`（**変更**）: `activeSlotProvider` を読み、
  非 null の slotId で `ProgressRepository(prefs, slotId)` を返す。null の場合は
  `StateError`（UI 上はリダイレクトで未選択時に到達しない）。
  → **既存の treasure_map / seek_find 画面は無改修**で自動的にアクティブスロットを操作。

> 生成/リセットは任意スロットを対象にするため、`SaveSlotController` 内で
> `ProgressRepository(prefs, slotId)` を都度生成して同一キー方式を再利用する
> （`progressRepositoryProvider` のアクティブスロット束縛とは別経路）。

---

## 5. 画面とルーティング

### 5.1 ルート

| パス | 画面 | 備考 |
|---|---|---|
| `/slots` | `SlotSelectScreen` | **initialLocation**。スロット選択 |
| `/` | `TreasureMapScreen` | アクティブスロット必須 |
| `/hunt/:sceneId` | `SeekFindScreen` | 同上 |
| `/settings` | `SettingsScreen` | 言語切替・保護者ゲート入口 |

- `go_router` の `redirect`: `activeSlotProvider == null` かつ遷移先が `/slots` 以外なら `/slots` に送る。
- ルーターを `activeSlotProvider` の変化で再評価するため `refreshListenable`（または
  `ChangeNotifier` 連携）を用いる。実装簡素化のため、選択直後に `context.go('/')` を呼ぶ方式でも可。

### 5.2 SlotSelectScreen

`lib/features/save_slots/slot_select_screen.dart`:

- タイトル（`tr(locale, 'slot.title')` 例: 「だれが あそぶ?」）。
- `kSaveSlots` を横並び（タブレット）/ 折返しで 3 枚表示。各カード（key `slot-card.$id`）:
  - **作成済み**: アバター（明色）+「つづき」。タップ → `activeSlot.select(id)` → `context.go('/')`。
    右上に小さなリセットボタン（ゴミ箱, key `slot-reset.$id`）→ `ParentalGate.show` →
    OK なら `resetSlot(id)`。
  - **未作成**: アバター（淡色）+「＋ あたらしく」（key `slot-new.$id`）。タップ →
    `createSlot(id)` → `activeSlot.select(id)` → `context.go('/')`。
- 最小タッチターゲット 60×60dp（`KidsButton` 流用可）。

### 5.3 main.dart

- 起動時グローバル `ensureInitialUnlock` は**廃止**（スロット生成時に実行）。
- `main()` は `WidgetsFlutterBinding.ensureInitialized()` → `SharedPreferences.getInstance()` →
  `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], ...))` のみ。

---

## 6. UX / 規制

- リセットは破壊的操作 → **保護者ゲート必須**（既存 `ParentalGate.show` stub を使用）。
- スロット選択は読めない子向けにアバター（絵）で識別。文字依存しない。
- データは端末ローカルのみ。第三者送信なし（規制方針は不変）。

---

## 7. テスト戦略

| 種別 | 対象 |
|---|---|
| Unit | `ProgressRepository` のスロット独立性（slot1 と slot2 が干渉しない）/ `clearAll` / `ensureInitialUnlock`。`SaveSlotRepository`（created 集合の add/remove）。`createSlot`/`resetSlot`（生成で scene01 解放、リセットで空に） |
| Widget | `SlotSelectScreen`: 3 枠表示 / 未作成タップで生成+遷移 / 作成済みタップで遷移 / リセットは保護者ゲート経由でのみ実行。`app_boot_test`: 起動が `/slots` であること |
| 既存更新 | `progress_repository_test`（slotId 付与）。`treasure_map_screen_test` / `seek_find_screen_test`（`activeSlotProvider` を override し、slot スコープのキーで初期化） |

- `shared_preferences` は `SharedPreferences.setMockInitialValues` を使用。
- すべて `fvm flutter test` / `bash scripts/check.sh` で緑にする。

---

## 8. 完成定義（DoD）

1. 起動すると `/slots` のスロット選択画面が出る。
2. 未作成スロットを選ぶと進捗が初期化され、宝の地図ホームに入れる。
3. 別スロットを選ぶと**独立した進捗**で始まる（一方のクリアが他方に影響しない）。
4. 作成済みスロットを選ぶと**続きから**遊べる（再起動後もスロットごとに保持）。
5. リセットは保護者ゲートを通過した時のみ実行され、対象スロットが空に戻る。
6. 言語設定は全スロット共通で、従来どおり保持される。

---

## 9. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| スロット | 固定 3・進捗のみ分離・固定アバター |
| 永続化 | `progress.<slotId>.*` + `save.createdSlotIds`（shared_preferences） |
| 状態 | `activeSlotProvider` + slotスコープの `progressRepositoryProvider`（既存画面は無改修） |
| 起動 | `/slots` 初期ルート + redirect |
| リセット | 保護者ゲート → `resetSlot`（`clearAll`） |
| 言語 | 全スロット共通（据え置き） |
