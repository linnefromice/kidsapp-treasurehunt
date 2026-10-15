# トレイルスタイル解放（難易度クリア連動）設計

## 目的

なぞりトレイルの「スタイル選択（ペンセレクト）」を難易度クリアで解放する。

- `solid`（たんしょく）= 常に使える
- `rainbow3`（にじ3しょく）= **easy（やさしい）を全シーンクリア**で解放
- `rainbowFull`（にじフル）= **hard（むずかしい）を全シーンクリア**で解放

ユーザー指示原文: 「このペンセレクト機能を難易度クリアで解放されるようにしたい / easy
クリアで3色、hard クリアで3色,虹」。3色は easy 時点で解放され hard でも引き続き使える
（累積）。

## 確定した方針（AskUserQuestion）

1. **解放スコープ = 端末ぜんたい・戻らない（global sticky）**
   - どれか 1 スロットがモードを全クリアすれば、そのペンは全スロットで解放。
   - 一度解放したら二度とロックに戻さない。
   - 既存の 100% クリア済みデータは「見た時」に解放される（後方互換）。
   - 実体は SettingsRepository のグローバル bool フラグ。
2. **ロック表示 = 🔒つきで見せる＋やさしいヒント**
   - ロック中スタイルもチップとして表示し、🔒 アイコン＋やさしい解放ヒントを出す。
   - 競争・スコア・煽りは入れない（キッズ UX）。

## レイヤー設計

進捗は「スロット×モード」スコープ、トレイル設定は「全スロット共通」。この非対称を
**global sticky 解放**で吸収する。

- **data 層（features 非依存・生文字列）**
  - `SettingsRepository`: スタイル id 文字列でキーした解放フラグ。
    - key: `settings.trailUnlock.<styleId>`、既定 false。
    - `bool trailStyleUnlocked(String styleId)` / `Future<void> setTrailStyleUnlocked(String styleId)`（true 固定 = sticky）。
  - `ProgressRepository`: 全クリア判定ヘルパー。
    - `bool isModeFullyCleared(GameMode mode, Iterable<String> sceneIds)`
      = `sceneIds` が空でなく、全てが当該モードで cleared。
- **domain（feature 層・方針マッピング）**
  - `TrailStyle.unlockRequirement`: `GameMode?`
    - solid → null（常時）、rainbow3 → `GameMode.easy`、rainbowFull → `GameMode.hard`。
    - `shared/game_mode.dart` を import（shared は下位レイヤーなので可）。
- **providers.dart（オーケストレーション）**
  - `Future<void> syncTrailUnlocks(ProgressRepository, SettingsRepository)`:
    全カタログを見て、満たした要件のフラグを sticky に立てる（永続化のみ）。
  - `unlockedTrailStylesProvider: Provider<Set<TrailStyle>>`:
    UI の真実源。`solid` は常に含む。各 style は
    「永続フラグ OR アクティブスロットの live 進捗が全クリア」なら解放扱い。
    さらに `unawaited(syncTrailUnlocks(...))` で sticky 永続化（後方互換・端末ぜんたい）。
- **解放確定点（クリア時）**
  - `seek_find_screen._handleComplete`: `completeScene` 直後に
    `syncTrailUnlocks(progress, settingsRepo)` を呼ぶ。
    → 設定を開かなくても・スロットを跨いでも sticky に解放が残る。

## UI（settings_screen.dart）

- `unlockedTrailStylesProvider` を watch。
- スタイルチップ: 解放済み = 通常 ChoiceChip。ロック中 = `avatar: Icons.lock_outline`、
  `onSelected: null`（選択不可）、`selected: false`。ValueKey は据え置き（テスト互換）。
- ロック中スタイルがあれば、Wrap の下に各ロックスタイルの🔒＋やさしいヒント行を出す。
- サブピッカー switch は `trail.style`（常に解放済み・sticky）で駆動するので不変。

## 文字列（strings.dart / ja・en）

- `trailStyle.rainbow3.lockedHint`
  - ja: 「やさしいを ぜんぶ クリアすると つかえるよ」
  - en: 'Clear all Easy scenes to unlock'
- `trailStyle.rainbowFull.lockedHint`
  - ja: 「むずかしいを ぜんぶ クリアすると つかえるよ」
  - en: 'Clear all Hard scenes to unlock'

（モード名は home トグルの `home.modeNormal`='ふつう' / `home.modeHard`='むずかしい'、
easy は「やさしい」に合わせる。）

## テスト（TDD）

**Unit**
- `TrailStyle.unlockRequirement`: solid→null / rainbow3→easy / rainbowFull→hard。
- `ProgressRepository.isModeFullyCleared`: 空→false / 部分→false / 全クリア→true /
  モード独立。
- `SettingsRepository.trailStyleUnlocked`: 既定 false / set で true / style 別独立。
- `syncTrailUnlocks`: 部分クリアでは立てない / 全クリアで立てる / sticky（戻さない）。
- `unlockedTrailStylesProvider`: solid 常時 / easy 全クリアで rainbow3 / hard 全クリアで
  rainbowFull / フラグのみでも live 進捗のみでも解放 / 永続化される。

**Widget（settings_screen）**
- 未クリア時: rainbow3・rainbowFull は🔒付きで表示され選択不可（タップしても style 不変）、
  ヒント文が出る。
- フラグ解放済み（prefs シード）時: 既存テスト同様に選択でき、サブピッカーが出る。
- 既存テスト（rainbow3/rainbowFull 選択系）は解放フラグを prefs にシードして維持。

## 影響範囲・互換

- 既存の settings 系 widget テストは rainbow3/rainbowFull がデフォルトでロックになるため、
  解放フラグのシードを追加して更新する（破壊的だが追加修正で吸収）。
- 機能は加算的（既存進捗・既存設定は壊さない）。アーキ変更なし。
