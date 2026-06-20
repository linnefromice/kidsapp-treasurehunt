# トレイル色ステータスバッジ & アバター表示 — 設計仕様

**日付**: 2026-06-20  
**対象画面**: `TreasureMapScreen`（`lib/features/treasure_map/treasure_map_screen.dart`）

---

## 1. 目的

マップ画面を開いただけで「今どのトレイル色か」「誰が遊んでいるか」がひと目でわかるようにする。  
設定画面に入らなくても現在の設定が視認でき、かつバッジからワンタップで設定変更に行ける。

---

## 2. スコープ

- **変更ファイル**: `treasure_map_screen.dart` のみ（AppBar 部分）  
- **新規ウィジェット**: `_TrailBadge`（同ファイル内プライベート）  
- **既存ロジック変更なし**（プロバイダー・モデル・ルーター・文字列は触らない）

---

## 3. AppBar の変更

### 3-1. Leading — アバター絵文字ボタン

| 項目 | 内容 |
|------|------|
| 変更前 | `Icon(Icons.person)` |
| 変更後 | アバター絵文字を `Text(fontSize: 28)` で表示 |
| タップ動作 | 変更なし（`activeSlotProvider.notifier.deselect()` → `/slots`） |
| データソース | `saveSlotControllerProvider[activeSlotProvider]` |
| フォールバック | フリーモード or 絵文字が取れない場合 → `Icon(Icons.person)` |
| タップ領域 | `IconButton` ラッパーで 48dp（Material デフォルト）を維持 |

```
変更後イメージ: [🐱] たからの ちず ... [クリア 2/13 🏆] [●●●] [⚙]
                  ↑アバター                               ↑バッジ
```

### 3-2. Actions — トレイルカラーバッジ（設定ボタンの左隣）

**新規プライベートウィジェット** `_TrailBadge` を追加し、設定 `IconButton` の直前に差し込む。

**バッジのビジュアル（スタイル別）**:

| TrailStyle | 表示内容 |
|------------|---------|
| `solid` | 単色の丸（直径 22dp）× 1 |
| `rainbow3` | 3つの丸（直径 16dp）横並び ＋ 間隔 2dp |
| `rainbowFull` | `SweepGradient` の丸（直径 22dp）× 1 |

**共通仕様**:
- タップ → `context.go('/settings')`
- `IconButton` の `padding` を利用し、タップターゲット 60dp 以上を保証
- 丸には `Colors.black26` の薄い枠（`Border.all`）を付ける（淡色・白で背景に埋もれない）
- セマンティクス: `Semantics(label: 'トレイル色: ${スタイル名}', button: true)`

**Actions の最終的な並び順**:

```
[クリアカウンタ テキスト]  [_TrailBadge]  [設定 IconButton]
```

---

## 4. 追加 watch プロバイダー

`_TreasureMapScreenState.build()` に以下を追加する：

```dart
final trail = ref.watch(trailSettingControllerProvider);
final activeSlotId = ref.watch(activeSlotProvider);
final slots = ref.watch(saveSlotControllerProvider);
final avatarEmoji = (activeSlotId != null && activeSlotId != kFreeModeSlotId)
    ? slots[activeSlotId]
    : null;
```

---

## 5. `_TrailBadge` ウィジェット仕様

```
_TrailBadge({
  required TrailSetting setting,
  required VoidCallback onTap,
})
```

内部で `setting.style` を switch してビジュアルを切り替える。  
`_ColorSwatch` 相当の実装（`settings_screen.dart` の `_ColorSwatch` はプライベートなので同等のコードを `treasure_map_screen.dart` 内に書く）。

---

## 6. テスト

既存の Widget テストに今回の変更は影響しない（`treasure_map_screen` はテスト対象外）。  
手動確認:
- [ ] マップ画面を開き、Leading にアバター絵文字が表示される
- [ ] フリーモード選択時は人アイコンにフォールバックする
- [ ] トレイルが `solid`（みずいろ）のとき、バッジが水色の丸 1 つ
- [ ] トレイルが `rainbow3` のとき、バッジが 3 つの丸
- [ ] トレイルが `rainbowFull` のとき、バッジが虹グラデーション丸
- [ ] バッジをタップすると設定画面に遷移する
- [ ] 設定でトレイル色を変えてマップに戻るとバッジが更新されている
