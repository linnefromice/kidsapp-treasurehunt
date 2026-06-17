# 複数シーン + 順次アンロック 設計書

- 日付: 2026-06-18
- 対象リポジトリ: `kidsapp-treasurehunt`
- ステータス: 設計確定（実装計画はこの後 writing-plans で作成）
- 前提: シーク＆ファインド MVP + セーブスロット実装済み
- 根拠: `ai-research-pipeline/.../reports/kids-treasure-hunt-game-design-and-features-2026.md`
  （D「ステージ/ワールド/アンロック」, F「図鑑の"あと少し"＝健全な再訪動機」, B「穏やかな区切り」）

---

## 1. 目的とスコープ

1 シーンのデモを、**複数シーンを順番に解放していく"ゲーム"** にする。シーンをクリアすると
次のシーンが開き、ゴール勾配（あと少し）で健全な再訪動機を作る。

### スコープ外（YAGNI）

- 実シーンのイラスト・実お題アート（背景はプレースホルダのグラデーションのまま。実アートは別途）
- スター/スコア/タイマー/レア収集（年齢別リワードは別機能）
- Dig 操作、ヒント自動強化、マスコット音声（別機能）
- ワールド（シーンのグループ）階層（今回はフラットな 3 シーン）

---

## 2. 決定事項

| 項目 | 決定 |
|---|---|
| 解放モデル | **順次アンロック**（シーン N クリア → N+1 解放） |
| シーン数 | 3（`scene01`=3 / `scene02`=4 / `scene03`=5 個のお題） |
| 完了後 | 完了演出「みつけたね！」+ **「ちずに もどる」ボタン**（戻ると次は解放済み） |
| 背景 | プレースホルダのグラデーションを**シーンごとに配色変更**（実アート前の視覚的区別） |
| 永続化 | 既存どおりアクティブスロットの `progress.<slotId>.*`（解放/クリア） |

---

## 3. データ

### 3.1 シーン定義（assets）

- 新規: `assets/scenes/scene02.json`（4 お題）, `assets/scenes/scene03.json`（5 お題）。
  - 形式は既存 `scene01.json` と同一（`id`/`titleKey`/`imageAsset`/`targets[]`、各 target は
    `id`/`labelKey`/正規化 `left,top,width,height`）。
  - お題は重ならない正規化 Rect で配置（サイズ目安: 0.12〜0.18）。`imageAsset` は将来用に保持。
- `scene01.json` は変更しない。

### 3.2 文字列（`lib/shared/strings/strings.dart`）

- 新規お題ラベル `target.*`（scene02/03 で使う分）を ja/en 両方に追加。
- 完了画面ボタン `seek.toMap`（ja「ちずに もどる」/ en「Back to map」）を追加。
- 既存 `scene.scene02.title` / `scene.scene03.title` は既にあるため流用。

---

## 4. ロジック

### 4.1 カタログのヘルパー

`lib/scenes_catalog.dart` に追加:

```dart
/// kSceneCatalog の並び順で次のシーン id を返す。最後なら null。
String? nextSceneId(String id) {
  final i = kSceneCatalog.indexWhere((e) => e.id == id);
  if (i < 0 || i + 1 >= kSceneCatalog.length) return null;
  return kSceneCatalog[i + 1].id;
}
```

### 4.2 完了時の順次アンロック

`lib/features/seek_find/seek_find_screen.dart` の `_handleComplete(sceneId)` を拡張:

```dart
Future<void> _handleComplete(String sceneId) async {
  final progress = ref.read(progressRepositoryProvider); // アクティブスロットにスコープ
  await progress.markCleared(sceneId);
  final next = nextSceneId(sceneId);
  if (next != null) {
    await progress.unlock(next);
  }
  await ref.read(audioServiceProvider).playComplete();
  if (mounted) setState(() => _completed = true);
}
```

- 最後のシーン（`scene03`）クリア時は `next == null` で unlock は no-op（全クリア）。
- 解放はアクティブスロットにスコープされるため、**スロットごとに独立**して進行する。

---

## 5. 画面 / UX

### 5.1 完了表示（seek_find_screen）

`_completed` が true のとき、現在の「みつけたね！」テキストに加えて
**`KidsButton`「ちずに もどる」** を表示し、押下で `context.go('/')`。

```dart
if (_completed)
  Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tr(localeCode, 'seek.complete'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        KidsButton(
          label: tr(localeCode, 'seek.toMap'),
          onPressed: () => context.go('/'),
        ),
      ],
    ),
  ),
```

### 5.2 シーン背景の配色（プレースホルダ）

`seek_find_screen` の背景グラデーションを、固定 1 色対から**シーン id で出し分け**る。
small なパレット（id → 2 色）を screen 内に持ち、未定義 id は既定色にフォールバック。
モデル（SceneDef）は変更しない。

```dart
const _sceneGradients = <String, List<Color>>{
  'scene01': [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
  'scene02': [Color(0xFFBBDEFB), Color(0xFFD1C4E9)],
  'scene03': [Color(0xFFFFE0B2), Color(0xFFFFCCBC)],
};
// 描画時: _sceneGradients[scene.id] ?? const [Color(0xFFB2DFDB), Color(0xFFC8E6C9)]
```

### 5.3 ホーム（treasure_map）

**無改修**。クリアで `clearedSceneIds` に追加、次が `unlockedSceneIds` に追加されるため、
戻るとカードがロック→解放、クリア済みに ✓ が反映される。最後のシーン後は全カードが
解放/クリア状態になる。

---

## 6. テスト戦略

| 種別 | 対象 |
|---|---|
| Unit | `nextSceneId`（scene01→scene02 / scene02→scene03 / scene03→null / 未知→null）。`SceneDef.loadAsset` が `kSceneCatalog` 全 id（scene01/02/03）を読めること（targets が空でない） |
| Widget | seek_find 完了で **次シーンが解放される**（scene01 クリア後 `progressRepositoryProvider.isUnlocked('scene02')` が true）。完了画面の「ちずに もどる」ボタンで `/` に遷移する |
| 既存 | seek_find / treasure_map のテストはアクティブスロット設定済みのまま流用。完了テストは unlock-next の assert を追加 |

- `shared_preferences` は `SharedPreferences.setMockInitialValues`、Flutter テストは `fvm flutter test`。
- 全体は `bash scripts/check.sh` を緑にする。

---

## 7. 完成定義（DoD）

1. scene01 をクリアすると scene02 が解放され、ホームでロック→解放に変わる。
2. scene02 をクリアすると scene03 が解放される。scene03 クリアで全クリア（次解放は無し・エラーなし）。
3. 各シーンは背景配色が異なり、お題数（3/4/5）も異なる。
4. 完了画面に「みつけたね！」+「ちずに もどる」ボタンが出て、押すとホームに戻る。
5. 進行はセーブスロットごとに独立（別スロットは別進行）。

---

## 8. 確定事項サマリ

| 項目 | 決定 |
|---|---|
| 解放 | 順次（完了ハンドラで `markCleared` + `unlock(nextSceneId)`） |
| データ | scene02.json(4) / scene03.json(5) 追加、target/seek.toMap 文字列追加 |
| 画面 | 完了に「ちずに もどる」ボタン、背景グラデをシーン別に |
| ホーム | 無改修（既存の解放/クリア表示で反映） |
| 進行スコープ | アクティブスロット（既存の `progressRepositoryProvider`） |
