# レア宝の強化 ＆ 称号/バッチ システム 設計

## 現状（前提）
- レア宝(C4): rare_gem/rare_crown/rare_medal（SVG有）。**リプレイ/フリーのみ** kRareTreasureChance=0.18 で
  ダミー枠を借りて1つ出現（withRareTreasure）。図鑑「とくべつ」に記録（discovered の rare_*）。
  描画は通常宝と同じ（特別アニメ無し）。レアは隠さない（withThemedCovers で除外）。
- 進捗: progress_repository … isCleared(mode,scene) / clearedSceneIds(mode) / isModeFullyCleared(mode,ids)。
  保存 progress.<slot>.*。図鑑: collection.<slot>.discovered / .unseen。完成 collectionProgressOf.isComplete。
- 解放先行例: 図鑑コンプ→rainbowFull解放 / Hard全クリア→解放（settings.trailUnlock.<id> sticky）。
- 設計原則: 失敗を罰しない / 競争・スター・リーダーボードは入れない / climax に多感覚集中 / 読字非依存。

---
## A. レア宝の強化

### A-1 [要望1] 各ステージにランダム出現
現状リプレイ限定 → **初回プレイ含む全エントリ**でロール（each stage に存在しうる）。
- 案: `_maybeShuffleOnReplay` で replay 条件に依らず `random < kRareChance` を判定し withRareTreasure 適用。
  （配置スキャッタや C2 は従来通り replay 条件のまま。レアだけ常時ロール）。
- 確率: 据え置き0.18 か 引き上げ（0.25 など）。要決定。
- 「各ステージに必ず1つ」保証は **しない**（毎回必ずだと特別感が薄れる）。確率＋たまに出る、を維持。
  （オプション: 初回クリア時だけ確率を上げる pity も可）。

### A-2 [要望2] 拾うと特別アニメーション
通常の FoundBurst と別に **レア専用リビール overlay**（climax 演出・SDKのみ）:
- フルスクリーン暗転スポットライト → レア宝が中央へズームイン → 放射状の光線(CustomPainter) →
  きらめきシャワー → 「✨ とくべつ！ ✨」バナー → 図鑑/とくべつ枠へ吸い込まれて消える。約1.5–2.5s。
- タップで早送り/閉じる。専用SE（任意）。発見の瞬間に演出集中する原則と合致（レア=climax）。
- 実装: RareRevealOverlay（_completed と同様 Stack 最前面に条件表示）。1本のControllerでシーケンス。

### A-3 記録/連携
- 既存どおり discovered に記録。バッチ（B）の「レア発見」条件にも使う。
- 任意: レア種を増やす（テーマ別レア等）は別途。当面 3 種維持。

### A-4 要決定（A）
- 出現範囲: 全エントリ常時ロール（推奨） / リプレイのみ＋初回保証
- 確率: 0.18据え置き / 0.25へ
- 演出強度: フル climax overlay（推奨） / 控えめ（その場で拡大＋光のみ）

---
## B. 称号/バッチ システム

### B-0 競争回避の枠組み（最重要）
スター/競争/順位/時間ではなく、**「あつめる」コレクション**として設計（宝図鑑の兄弟）。
- 罰しない・急かさない・未取得は「これから」。表示は絵＋音、読字非依存。
- バッチ＝達成のお祝い記念。数を競わせない・ロックで煽らない（locked はそっとシルエット）。

### B-1 データモデル
- Badge(id, labelKey, descKey, iconId, criteria)。
- 保存: badges.<slot>.earned（id集合・sticky）/ badges.<slot>.unseen（NEW バッジ用）。slot 名前空間。
- 純粋判定 `evaluateBadges(progress, collection, rareCount)` → Set<earnedId>（既存データから算出）。
- 解放系と同じ idempotent パターンで「新規取得分」を永続化し、取得アニメを発火。

### B-2 バッチ候補（非競争のマイルストーン・8〜12個）
1. first_find  はじめて たからを みつけた
2. first_clear はじめて ステージ クリア
3. world_complete どこかのワールドの宝を ぜんぶ あつめた
4. easy_all   やさしい ぜんぶ クリア
5. normal_all ふつう ぜんぶ クリア
6. hard_all   むずかしい ぜんぶ クリア
7. collection_complete 図鑑コンプリート
8. rare_first はじめての レア宝
9. rare_all   レア宝 3しゅ ぜんぶ
10. explorer  ぜんステージで なにか みつけた
（速さ/連続などスコア系は入れない）

### B-3 取得タイミング/演出
- 評価フック: シーンクリア時 / 図鑑入場時 / レア取得時に evaluateBadges → 新規があれば永続化＋
  「バッチ ゲット！」overlay（小さな祝福：バッジがポンとスタンプ＋きらめき＋ラベル）。A-2 とコンポーネント共有可。

### B-4 ギャラリー（収集を見る場所）
- ルート /badges（または図鑑画面にタブ追加）。取得=カラー＋説明、未取得=シルエット（図鑑と同じ出し分け）。
- ホーム or 図鑑から入口。保護者ゲート不要（閲覧のみ）。

### B-5 バッジアイコン
- 専用SVGを generator で生成（リボン/メダル/星章など 8〜12）。または既存(crown/medal/gem/star…)流用。
- 推奨: 専用バッジSVGで統一感（generatorに追加・ドリフトテストで検証）。

### B-6 要決定（B）
- 競争回避フレーム: コレクション型でOKか（原則に照らし要確認）
- バッジ規模: 上記10前後 / もっと絞る(6) / もっと増やす
- アイコン: 専用SVG新規（推奨） / 既存流用
- ギャラリー配置: 専用ルート /badges / 図鑑にタブ追加

---
## 実装フェーズ（設計確定後）
- PR-R1: レア常時ロール＋確率（A-1）
- PR-R2: レア専用リビール overlay（A-2）
- PR-B1: badges データ層（model/repository/evaluate/provider）＋テスト
- PR-B2: バッジSVG生成＋登録（B-5）
- PR-B3: 取得演出＋ギャラリー画面（B-3/B-4）

---
## 確定事項（ユーザー回答）
- レア出現: **全エントリ常時ロール・確率 約0.20**（初回プレイも対象。必ずは出さない）。
- バッチ: **コレクション型**（数を競わせない・順位なし・未取得シルエット・急かさない）。
- ギャラリー: **図鑑画面にタブ追加**（ワールド別/なかま別 と並ぶ第3タブ「しょうごう」）。
- バッジアイコン: **専用SVGを generator で新規生成**（リボン/メダル/星章 等・統一感）。

## 確定 実装ロードマップ
- **PR-R1**: レアを全エントリ常時ロール化（replay 条件から分離）＋ kRareTreasureChance 調整（→0.20）。
  既存テスト（rare 出現がリプレイ限定前提のものがあれば）を更新。
- **PR-R2**: レア専用リビール overlay（climax 演出）＋ seek_find での発火（rare 発見検知）。
- **PR-B1**: badges データ層 = Badge model / badge_catalog（id・label・desc・icon・criteria）/
  evaluateBadges(progress, collection, rareCount) / BadgeRepository（badges.<slot>.earned/.unseen）/
  badgesProvider。純粋判定の unit テスト。
- **PR-B2**: バッジ専用SVG（8〜12）を generator 追加＋ target_icons 風の badge_icons 登録＋ドリフトテスト。
- **PR-B3**: 取得演出（A-2 と共有の祝福 overlay）＋ 図鑑「しょうごう」タブ（取得=カラー/未取得=シルエット）。
  評価フック（クリア時/図鑑入場時/レア取得時）で新規取得を永続化＋演出発火＋NEWバッジ。

## 共有部品
- CelebrationOverlay: レアリビール(A-2)とバッチ取得(B-3)で共有。放射光線(CustomPainter)＋中央ズーム＋
  きらめき＋ラベル＋タップ閉じ。SDKのみ。
