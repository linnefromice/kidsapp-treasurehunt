# kidsapp-treasurehunt

子供向けの **2D 教育アプリ**（宝探しテーマのミニゲーム集）。Android タブレット /
iPad 向けに **Flutter** で個人開発する。本リポジトリは実装が始まる前の
**開発方針・実装方針** を定義する。

> このドキュメントは以下の Deep Research レポートを一次根拠としている：
> `ai-research-pipeline/features/deep-research/reports/flutter-kids-2d-educational-apps-2026.md`
> （調査日 2026-06-17 / 公式一次情報 30 件以上）

---

## 1. コンセプト

「宝の地図」を進めながら **3 つのミニゲーム** をクリアして宝を集める、未就学〜
低学年（5〜11 歳）向けの学習アプリ。ホーム画面を宝の地図に見立て、各ミニゲームを
ステージとして配置する「ミニゲームコレクション」形式を採る。

| ミニゲーム | 学習要素 | 宝探しでの位置づけ |
|---|---|---|
| **迷路 (Maze)** | 空間認識・運筆 | 地図を辿って宝箱までの道を探す |
| **間違い探し (Spot the Difference)** | 観察力・集中力 | 2 枚の地図の違いを見つけて手がかりを得る |
| **タイピング (Typing)** | ひらがな習得 | 呪文（ことば）を入力して宝箱を開ける |

- **対象プラットフォーム**: Android タブレット / iPad（タブレット横向きを第一級でサポート）
- **対象年齢**: 5〜11 歳（難易度を年齢帯で切替）
- **言語**: 日本語 / 英語（ja/en）

---

## 2. 技術選定（方針）

フレームワークは **Flutter 確定**。Flutter 内の選定は調査結論に従う。

### 2.1 描画・ゲーム実装

**原則「純 Flutter」**。ゲームループや物理が要らない限り Flame は入れない。

| ミニゲーム | 採用 | 理由 |
|---|---|---|
| 迷路 | 純 Flutter（`CustomPainter` + `canvas.drawLine`） | グリッド描画・移動のみ。物理不要。キャラのアニメ演出を足す段階でのみ Flame を検討 |
| 間違い探し | 純 Flutter（`InteractiveViewer` + `Stack`） | 静的画像対話。ズーム/パンは InteractiveViewer で完結 |
| タイピング | 純 Flutter（自作ひらがなキーボード） | IME の composing 問題を避けるため OS の IME は使わない |

> Flame を採用する場合のみ `flame 1.37.0`（Flutter Favorite）を候補とする。

### 2.2 基盤ライブラリ

| 用途 | 採用 | バージョン基準 |
|---|---|---|
| 状態管理 | **Riverpod** + `riverpod_generator`（`@riverpod` + build_runner） | 3.3.2 系 |
| ルーティング | **go_router** | 14.8.0 系 |
| 音声 | **audioplayers**（通信なし・効果音のみ） | 6.7.x |
| かな変換 | **kana_kit**（ひらがな↔ローマ字↔カタカナ） | 2.1.1（メンテ頻度は要監視） |
| ローカライズ | `flutter_localizations` + `intl` | — |
| ゴールデンテスト | **alchemist** | — |

### 2.3 入れない SDK（Kids 規制のため厳守）

```
絶対に入れない:
  Firebase Analytics / Crashlytics  … Apple Kids Category は「コード削除」が必要（disable 不可）
  AdMob 行動広告 / AppsFlyer / Adjust / Facebook SDK … COPPA・Families 違反
  Google Maps 等の位置情報              … Families 禁止
設計原則: 行動広告 SDK ゼロ・データ収集ゼロ・保護者ゲートを MVP に含める
```

---

## 3. プロジェクト構成（方針）

**単一アプリ内 feature 分割**（Melos monorepo は個人開発には過剰）。

```
lib/
  main.dart
  router.dart                     # go_router 定義
  features/
    maze/        (MazeGenerator, MazePainter, MazeGameNotifier)
    spot_diff/   (SpotDiffPuzzle, DiffSpot, SpotDiffNotifier)
    typing/      (HiraganaKeyboard, TypingScorer, TypingNotifier)
    treasure_map/(ホーム=宝の地図、進捗・解放管理)
  shared/
    widgets/        (KidsButton, ScoreBoard, FeedbackAnimation)
    audio/          (AudioService / audioplayers)
    parental_gate/  (ParentalGateDialog)
    l10n/           (app_ja.arb, app_en.arb)
    theme/          (KidsTheme, breakpoints)
test/
  unit/    (迷路到達可能性 / TypingScorer / Rect.contains ヒット判定)
  widget/  (MazePainter 描画 / ParentalGateDialog / KidsButton)
  golden/  (alchemist: タブレット + スマホ両解像度)
```

ルーティングは `/`（宝の地図）、`/maze`、`/spot-diff`、`/typing`、`/settings`。

---

## 4. ミニゲーム実装方針

### 4.1 迷路 (Maze)
- 生成: **DFS Backtracking**（直線的で子供にやさしい）。出口到達可能性を Unit Test で担保。
- 描画: `CustomPainter` で壁を `drawLine`、プレイヤーを `drawCircle`。
- 操作: 4 方向ボタン（最小 60×60 dp）+ `onPanUpdate` ドラッグ。
- 難易度: かんたん 5×5 / ふつう 8×8 / むずかしい 12×12。

### 4.2 間違い探し (Spot the Difference)
- データ: 差分は **0.0〜1.0 正規化 Rect** で JSON 管理（`assets/puzzles/*.json`）。
- ヒット判定: スクリーン座標 →（`InteractiveViewer` 逆行列）→ シーン座標 → 正規化座標 の 2 段変換。`Rect.contains` で判定。**Unit Test 必須**（ズレやすい）。
- ジェスチャ: InteractiveViewer 内は `onInteractionStart/Update/End` を使う（`onScale*` と干渉させない）。
- レイアウト: タブレット横 = 左右 2 枚（Row）、スマホ = 上下（Column）。
- 難易度: 差分 3/5/7 箇所、サイズ大/中/小、ヒント回数で調整。

### 4.3 タイピング (Typing)
- **自作ひらがなキーボード**（OS IME 非依存。子供 UX の核心）。
- 採点: 部分一致スコア（リアルタイム）+ 完了スコア（ミス文字数ベース）。
- お題は年齢帯別（年少: あ/い/う → 中学年: にじいろ 等）。

---

## 5. 子供向け UX チェックリスト（実装基準）

| 要件 | 基準 |
|---|---|
| タッチターゲット | 最小 60×60 dp（6 歳以下） |
| 誤タップ防止 | 重要操作間 0.5s 以上（`IgnorePointer` + `Future.delayed`） |
| 非テキスト UI | アイコン + 音声ナビ（`Semantics` + flutter_tts） |
| 音声フィードバック | 正解=明るい音 / 誤=低い音 |
| 達成演出 | クリアで星・キャラがジャンプ（`AnimationController`） |
| 色覚対応 | 赤/緑のみに依存しない（形 + パターン併用） |
| コントラスト | WCAG AA 4.5:1 以上 |
| 保護者ゲート | 設定・課金・外部リンク前に算数問題ダイアログ必須 |
| タブレット横向き | 2 カラム（`LayoutBuilder` / `OrientationBuilder`） |

---

## 6. 規制対応（最重要リスク・2026）

> **免責**: 以下はレポート（2026-06-17 時点の公式一次情報の解釈）に基づく開発方針であり法的助言ではない。**リリース前に弁護士等へ最終確認する**。

同時に満たすべき 3 セット:

| 規制 | 開発側の対応 |
|---|---|
| **COPPA / 2026 改正**（2026-04-22 発効） | データ収集ゼロ設計。第三者共有なし。Firebase Analytics 除外 |
| **Apple Kids Category** | 保護者ゲート必須。第三者 analytics の **コード削除**（disable では不可）。Privacy Nutrition Labels = No Data Collected |
| **Google Play Families** | Self-Certified Ads SDK のみ（本アプリは広告なし）。位置情報なし。Console で対象年齢を正確に申告 |

**3 原則**: ①行動広告 SDK を一切入れない ②データ収集ゼロ設計 ③保護者ゲートを MVP に含める。

---

## 7. マネタイズ方針（kids-safe）

1. まず **完全買い切り**（¥120–¥360）でリリース。Kids Category で問題が少なく最もシンプル。
2. 反応を見て **保護者ゲート付き IAP**（追加ステージパック ¥99–¥250）を追加。
3. **行動広告は絶対に入れない**。

IAP は必ず「保護者ゲート（算数問題）→ `in_app_purchase`」の順で起動する。

---

## 8. テスト戦略

| 種別 | 対象 |
|---|---|
| Unit | 迷路の出口到達可能性 / `TypingScorer` / `Rect.contains` ヒット判定 / kana 変換 |
| Widget | `MazePainter` 描画 / `ParentalGateDialog` / `KidsButton` タップ |
| Golden | alchemist でタブレット + スマホ両解像度のスナップショット（視覚回帰検出） |

CI では PR ごとに `flutter analyze` + `flutter test` を必須化する。

---

## 9. AI 駆動開発（Claude Code）

```bash
# Dart MCP Server
claude mcp add --transport stdio dart -- dart mcp-server
# Flutter Agent Skills
npx skills add flutter/skills --skill '*' --agent universal
```

- GitHub Issues でタスク分割 → `/loop` で issue ごとに Claude Code を自走。
- Agentic Hot Reload で変更を即確認、alchemist Golden Test で視覚回帰を自動検出。

---

## 10. ロードマップ（優先順）

```
Week 1: 雛形 + Riverpod + go_router + KidsTheme + 宝の地図ホーム
Week 2: 迷路   — DFS 生成 + MazePainter + 4 方向ボタン
Week 3: 間違い探し — サンプル画像ペア + 座標変換ヒット判定
Week 4: タイピング — 自作ひらがなキーボード + 採点
Week 5: 共通    — audioplayers + 保護者ゲート + 多言語 (ja/en)
Week 6: タブレット最適化 + Golden Test + アクセシビリティ
Week 7: ストア素材 + Families / Kids Category 申請 + リリース
```

初期 Issue 候補: 迷路生成 / MazePainter / 迷路移動・クリア判定 / 間違い探しデータ /
ヒット判定 / ひらがなキーボード / TypingScorer / 保護者ゲート / Golden Test /
ja-en ARB / タブレット responsive / AudioService / ストア素材。

---

## 付録: 主要スニペットの所在（レポート参照）

迷路描画（CustomPainter）、間違い探しのタップ座標変換、タイピング採点、保護者ゲート
ダイアログの実装スニペットは根拠レポートの「付録: コードスニペット集」にある。実装時は
そこを起点にする。

---

## ライセンス / アセット方針

- 効果音・画像は CC0 / CC BY（freesound.org, opengameart.org, Pixabay）を使用し、帰属が必要なものは `CREDITS.md` に明記する。
- フォント: 日本語 = M PLUS Rounded 1c、英字 = Fredoka One / Nunito（Google Fonts）。

---

_本 README は実装着手前の方針定義であり、実装の進行に合わせて更新する。_
