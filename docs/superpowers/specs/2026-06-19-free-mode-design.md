# フリーモード（全マップ解放モード）設計

**Goal:** スロット選択画面に「フリーモード」を追加し、全9マップを最初から自由に遊べる正式なモードを提供する。

**位置づけ:** 隠しデバッグ機能ではなく、子供がいつでも好きなマップを選んで遊べる「自由に遊ぶ」モード。

---

## コンセプト

固定3スロット（「だれが あそぶ?」のアバター）と並ぶ **4枚目のカード** として
フリーモードを追加する。タップすると全シーンが解放済みの状態で宝の地図ホームへ遷移する。

- 入り口: スロット選択画面の4枚目カード
- 保護者ゲート: なし（全マップ解放は単なるゲーム体験であり、規制上の保護者ゲート対象＝
  設定・課金・外部リンクには該当しない）
- リセット: なし（常に全解放のためリセット概念が不要）

## データ設計

既存の進捗パイプライン（`progressRepositoryProvider` が `activeSlotProvider` に
スコープして `isUnlocked`/`isCleared` を読むだけ）にそのまま乗せる。地図・探索画面は
**一切変更しない**。

- 専用スロット id `kFreeModeSlotId = 'free'` を新設。3つの実スロットとは進捗キーの
  名前空間が独立（`progress.free.*`）。実スロットの進捗には一切影響しない。
- `ProgressRepository.unlockAll(List<String> sceneIds)` を追加。渡された全シーンを
  `unlockedSceneIds` に書き込む（冪等：再実行しても結果は同じ）。
- フリーモード入場時に「全カタログ id を `unlockAll`」してから `activeSlot='free'` を
  選択し `/` へ遷移する。**入場のたびに再シード**するため、将来マップを追加しても
  自動的に全解放される（`kSceneCatalog` を単一の真実の源とする）。
- クリア/発見の進捗は `free` 名前空間に通常どおり蓄積される。

## UI

- `slot_select_screen.dart` に `_FreeModeCard` を追加（既存3カードの後ろ・4枚目）。
  - アバター: `Icons.auto_awesome`（3つの動物アバターと差別化）
  - ラベル: `slot.free`（ja「フリーモード」/ en「Free Mode」）
  - 既存 `_SlotCard` の見た目（Card + InkWell + 160x200 + アイコン+ラベル）に揃える。
  - リセットボタン（delete アイコン）は持たない。
- カードのキー: `slot-card.free`、ラベルキー: `slot-free`。

## 既知の挙動（許容）

地図ノードの「現在地」表示は `unlocked && !cleared` で判定されパルス（拡大）アニメが付く。
フリーモード初回は全9ノードが未クリアのため **全ノードがパルス** する。動作上の問題は
なく「全部すぐ遊べる」と読めるため、MVP では抑制しない。賑やかすぎる場合はフリーモード
判定フラグで後からパルスを抑制できる（本スコープ外）。

## 変更ファイル

| ファイル | 変更 |
|----------|------|
| `lib/data/progress_repository.dart` | `unlockAll(List<String>)` 追加 |
| `lib/save_slots_catalog.dart` | `kFreeModeSlotId = 'free'` 定数追加 |
| `lib/providers.dart` | `SaveSlotController.enterFreeMode()` 追加 |
| `lib/features/save_slots/slot_select_screen.dart` | `_FreeModeCard` 追加 |
| `lib/shared/strings/strings.dart` | `slot.free`（ja/en）追加 |

## テスト戦略

- **Unit** (`progress_repository_test` / `scenes_catalog_test` 付近):
  - `unlockAll` が渡した全 id を unlocked にする。
  - `unlockAll` が冪等（2回呼んでも結果同一）。
  - `enterFreeMode` 後、`progress.free` 名前空間で全 `kSceneCatalog` が `isUnlocked`。
- **Widget** (`slot_select` 系):
  - スロット選択画面に4枚目「フリーモード」カードが表示される。
  - フリーモードカードのタップで `/`（宝の地図）へ遷移し、全ノードが `node-locked.*` でない
    （= 全解放）。
- 既存テスト（3スロット前提）が壊れないことを確認。

## 規制チェック（README §6）

- 追加 SDK なし・ネットワークなし・データ収集なし。フリーモードは端末ローカルの
  ゲーム進行のみ。行動広告 SDK・解析 SDK・位置情報は一切関与しない。
