# なぞり跡トレイルエフェクト + 色選択機能 — 設計

作成: 2026-06-20 (JST) / ブランチ予定: `feat/drag-trail-effect-color`

## 1. 目的

Easy モードで宝を「なぞって探す」とき、指の軌跡に追従して **キラキラ粒子トレイル**を表示する。
トレイルの色は設定画面でユーザーが選べる（全スロット共通の永続設定）。

> 子供向け原則: 失敗を罰しない控えめな演出。色は赤緑のみに依存せず、はっきり区別できる色相を用意。
> タッチターゲット 60dp 以上。データ収集ゼロ（端末ローカル shared_preferences のみ）。

## 2. 決定事項（ユーザー確認済み）

- **エフェクトの形**: キラキラ粒子トレイル（点が散って ~0.5s でフェード）。`MissBubble` と同じ
  「state のリストに追加 → ウィジェットが自前アニメ後に自分を削除」パターンを踏襲。
- **色パレット**: 単色 6 色を実装。初期色は `みずいろ`（既存 MissBubble と調和）。
  - みずいろ `#42A5F5` / ピンク `#FF6FA5` / きいろ `#FFD54F` / むらさき `#AB47BC` /
    オレンジ `#FF9800` / しろ `#FFFFFF`
- **にじ（色相変化タイプ）**: 今回は **設計のみ**（§7）。実装は次回。モデルに後から差し込める
  拡張点を用意する。
- **表示範囲**: Easy モードのドラッグ（pan-find）時のみ。Normal/Hard はドラッグが
  `InteractiveViewer` のパンに割り当てられているため対象外（タップ発見にはトレイルを出さない）。
- **永続スコープ**: `localeCode` と同様、全スロット共通の単一設定。
- **スロットリング**: 移動距離しきい値で間引き、同時表示の粒子数に上限を設けて軽量化。

## 3. アーキテクチャ / 影響ファイル

| 層 | ファイル | 変更 |
|----|----------|------|
| モデル | `lib/features/seek_find/models/trail_color.dart`（新規） | `TrailColorChoice` enum + `resolveTrailColor()` + パレット定義 |
| データ | `lib/data/settings_repository.dart` | `trailColorId()` / `setTrailColorId()` を追加 |
| プロバイダ | `lib/providers.dart` | `TrailColorController`（Notifier）+ `trailColorControllerProvider` |
| UI(設定) | `lib/features/settings/settings_screen.dart` | 「エフェクトのいろ」セクション（色スウォッチ ChoiceChip） |
| UI(演出) | `lib/features/seek_find/widgets/trail_sparkle.dart`（新規） | 1 粒子の自己消滅アニメ widget（MissBubble 流用） |
| 画面 | `lib/features/seek_find/seek_find_screen.dart` | pan 中に粒子を spawn（throttle）、Stack に重ねる |
| i18n | `lib/shared/strings/strings.dart` | `settings.trailColor` と 6 色名 (ja/en) |

### モデル: `TrailColorChoice`

```dart
enum TrailColorChoice {
  sky('sky', Color(0xFF42A5F5)),
  pink('pink', Color(0xFFFF6FA5)),
  yellow('yellow', Color(0xFFFFD54F)),
  purple('purple', Color(0xFFAB47BC)),
  orange('orange', Color(0xFFFF9800)),
  white('white', Color(0xFFFFFFFF));

  const TrailColorChoice(this.id, this.baseColor);
  final String id;
  final Color baseColor;

  static const fallback = TrailColorChoice.sky;

  static TrailColorChoice fromId(String? id) =>
      values.firstWhere((c) => c.id == id, orElse: () => fallback);
}

/// 粒子ごとの実際の色を解決する。にじ対応の拡張点（§7）。
/// 現状は単色なので particleIndex は未使用だが、将来 rainbow で使う。
Color resolveTrailColor(TrailColorChoice choice, {required int particleIndex}) =>
    choice.baseColor;
```

- 永続化は `id`（文字列）。未知 id は `fallback`（みずいろ）へフォールバック（境界での入力検証）。
- `resolveTrailColor` を経由させることで、`rainbow` 追加時に enum 1 値 + この関数 +
  パレット表示リストの変更だけで済む（screen/widget は無改修）。

### データ: SettingsRepository

```dart
static const _trailColorKey = 'settings.trailColor';

String trailColorId() =>
    _prefs.getString(_trailColorKey) ?? TrailColorChoice.fallback.id;

Future<void> setTrailColorId(String id) =>
    _prefs.setString(_trailColorKey, id);
```

### プロバイダ

```dart
class TrailColorController extends Notifier<TrailColorChoice> {
  @override
  TrailColorChoice build() =>
      TrailColorChoice.fromId(ref.read(settingsRepositoryProvider).trailColorId());

  Future<void> select(TrailColorChoice choice) async {
    await ref.read(settingsRepositoryProvider).setTrailColorId(choice.id);
    state = choice;
  }
}

final trailColorControllerProvider =
    NotifierProvider<TrailColorController, TrailColorChoice>(
      TrailColorController.new,
    );
```

### 演出: TrailSparkle（1 粒子）

- `MissBubble` を流用。`position`（シーン座標）+ `color` を受け取り、~500ms で
  小さく弾けてフェード。`IgnorePointer` でヒット判定を邪魔しない。
- サイズは MissBubble より小さめ（~16–20dp の光点）。複数が軌跡上に連なる。

### 画面の spawn ロジック（throttle + 上限）

```dart
// 定数
const _kTrailSpawnMinDistance = 18.0; // この距離以上動いたら 1 粒 spawn
const _kTrailMaxParticles = 24;       // 同時表示の上限（古いものから除外）

Offset? _lastTrailSpawn;

void _handlePanTrail(Offset localPosition) {
  final last = _lastTrailSpawn;
  if (last != null &&
      (localPosition - last).distance < _kTrailSpawnMinDistance) {
    return;
  }
  _lastTrailSpawn = localPosition;
  final choice = ref.read(trailColorControllerProvider);
  final color = resolveTrailColor(choice, particleIndex: _trailSeq++);
  final key = UniqueKey();
  setState(() {
    _trailSparkles.add((position: localPosition, key: key, color: color));
    if (_trailSparkles.length > _kTrailMaxParticles) {
      _trailSparkles.removeAt(0);
    }
  });
  // ウィジェット側のアニメ完了で自己除去（MissBubble と同様 Timer/onEnd）
}
```

- `onPanStart` で `_lastTrailSpawn = null` にリセット。`onPanUpdate` で発見処理
  （`_handleHit`）と spawn（`_handlePanTrail`）の両方を呼ぶ。
- Easy のみ（`_isLargeArea == false`）。既存の `onPanStart/onPanUpdate` が
  Easy だけ非 null な分岐に相乗り。

## 4. UX（設定画面）

言語セクションの下に「エフェクトのいろ / Trail color」を追加。`Wrap` + 6 個の
ChoiceChip。各 chip は色スウォッチ（円）+ 色名ラベル。選択中をハイライト。
chip の最小タップ領域 60dp を確保（`materialTapTargetSize` / padding）。

## 5. テスト戦略

- **Unit**
  - `TrailColorChoice.fromId`: 既知 id→該当、未知/null→fallback(sky)。
  - `resolveTrailColor`: 単色は particleIndex に依らず baseColor を返す。
  - `SettingsRepository`: trailColor の get 既定値=sky、set→get 往復、未設定時 fallback。
    （`SharedPreferences.setMockInitialValues`）
- **Widget**
  - 設定画面: 6 chip が描画される / chip タップで `setTrailColorId` 永続化 + 選択状態反映。
  - （トレイルの spawn は SeekFindScreen 同様 flutter_test 上でアニメ/ジェスチャが
    干渉しやすいので、粒子 spawn の純ロジックは throttle 判定を関数抽出して unit でも担保。
    画面挙動は実機「手動確認」に委ねる＝既存方針に整合。）
- `scripts/check.sh`（format / analyze / test）green を完了条件。

## 6. ドキュメント更新

- `docs/glossary.md`: 補足語彙に「Trail Sparkle（なぞりキラキラ）」を追加。
- `docs/development.md` の手動確認(DoD)に「Easy でなぞると指先にキラキラが追従。設定で色を変えられる」を追記。
- `README` の機能一覧に該当があれば一言追記（なければ不要）。

## 7. にじ（色相変化タイプ）の設計 — 今回は実装しない

将来 `rainbow` を足すときの差分を最小化する設計を先に固めておく。

- `TrailColorChoice` に `rainbow('rainbow', Color(0xFF42A5F5))`（baseColor はチップ表示用の
  代表色 or 専用スウォッチ）を 1 値追加。
- `resolveTrailColor(choice, particleIndex)` の `rainbow` 分岐で、`particleIndex` から
  HSV 色相を進める:
  ```dart
  TrailColorChoice.rainbow =>
      HSVColor.fromAHSV(1, (particleIndex * 18) % 360, 0.85, 1).toColor(),
  ```
  → 粒子ごとに色相が回り、軌跡が虹色に流れる。screen は `_trailSeq` を既に
  particleIndex として渡しているため**無改修**。
- 設定画面のパレットリストに rainbow chip（虹グラデのスウォッチ）を 1 つ足すだけ。
- i18n に `trailColor.rainbow`（にじ / Rainbow）を追加。
- これらの seam（`resolveTrailColor` 経由・`_trailSeq` 受け渡し・id ベース永続化）を
  今回の実装に含めることで、にじは「enum1値 + 関数1分岐 + chip1つ + 文言」で完結する。

## 8. 非対象（YAGNI）

- トレイルの ON/OFF トグル（要望は「色を選ぶ」。常時表示で開始）。
- タップ発見時のキラキラ（要望はドラッグ追従）。
- Normal/Hard でのトレイル（ドラッグ＝パンのため）。
- にじの実機実装（§7 は設計のみ）。
