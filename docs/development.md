# 開発ガイド（kidsapp-treasurehunt）

セットアップ・実行・テスト・配布の実務手順。設計の正典は `docs/superpowers/` の spec/plan、
プロジェクト方針は `README.md`、AI 運用は `CLAUDE.md` を参照。

---

## 1. 前提ツール

| ツール | 用途 | 備考 |
|---|---|---|
| **fvm** | Flutter バージョン管理 | `.fvmrc` の版（Flutter 3.44.2）を全環境で統一 |
| Android SDK | Android ビルド/実機 | Android Studio 同梱。`flutter doctor` で確認 |
| Xcode | iOS/iPad ビルド | macOS のみ |

```bash
# fvm 未導入なら
dart pub global activate fvm
```

> **重要**: 本リポジトリでは素の `flutter` を直接使わず、**必ず `fvm flutter` / `fvm dart`** を
> 使う。`.fvmrc` が唯一の真実の源で、CI も同じ版を読む（バージョンドリフト防止）。

---

## 2. 初回セットアップ

```bash
fvm install            # .fvmrc に書かれた Flutter 3.44.2 を取得
fvm flutter pub get    # 依存解決
```

Android 実機/ビルドを使う場合は一度だけライセンス承認:

```bash
fvm flutter doctor --android-licenses   # すべて y
fvm flutter doctor                       # 緑を確認
```

IDE 連携: SDK パスにリポジトリ直下の `.fvm/flutter_sdk`（シンボリックリンク）を指定すると
IDE も 3.44.2 に統一される。

---

## 3. 実行（ローカル実機 / エミュレータ）

```bash
fvm flutter devices         # 接続中のデバイス一覧
fvm flutter run             # デバッグ起動（ホットリロード）
fvm flutter run --release   # 本番に近い状態
fvm flutter run -d <deviceId>   # デバイスが複数あるとき
```

### Android タブレット/スマホ（USB）

1. 端末: 設定 > デバイス情報 >「ビルド番号」を 7 回タップ → 開発者オプション有効化。
2. 設定 > 開発者向けオプション >「USB デバッグ」を ON。
3. USB 接続 → 端末側の「このPCを許可しますか?」を**許可**。
4. `fvm flutter devices` に表示されたら `fvm flutter run`。

> タブレット横向きが第一級。確認は横向きで行う。

### iPad

1. iPad: 設定 > プライバシーとセキュリティ > デベロッパモード → ON（再起動）。
2. USB 接続 or 同一 LAN。
3. 署名設定:
   ```bash
   open ios/Runner.xcworkspace   # Signing & Capabilities で Team を設定（無料 Apple ID 可）
   fvm flutter run -d <ipadのdeviceId>   # 初回は pod install が走る
   ```
4. 端末側「設定 > 一般 > VPN とデバイス管理」で開発者を信頼。

### 手動確認（Definition of Done）

実機で以下を確認する:

1. 起動するとスロット選択画面。空きスロットは**白紙**（「あたらしく」）、フリーモード枠も並ぶ。
2. 白紙スロットをタップ → **絵文字ピッカー**が開く。1 つ選ぶとそのアバターでスロット作成 + ホームへ。
3. ホームは羊皮紙風の宝の地図。13 ワールドが曲線ルートで並び、`scene01` 解放・他はロック。
4. `scene01` → シーンに宝アイコンが見える（背景は環境アニメで動く）。図鑑バーにも未発見アイコン（グレー）が並ぶ。
5. 宝を**タップ**、または指/ペンで**なぞる**と発見（点灯 + 図鑑が埋まる）。タップの空振りは控えめなミスバブルのみで罰しない。Easy でなぞると指先に**キラキラが追従**する（なぞり中はミスバブルではなくキラキラ）。全部発見 → 「みつけたね！」。ホームに戻ると ✓ + 次シーン解放。
6. 8 秒ほど無操作で未発見の宝が 1 つわずかに光る（アイドルヒント）。操作すると消える。
7. アプリ再起動 → そのスロットが「つづき」表示、選ぶと続きから。別スロットを新規で選ぶと**独立した進捗**で始まる。
8. 作成済みスロットのゴミ箱 → 保護者ゲート → OK でリセット（白紙に戻り、アバターも消える）。
9. **フリーモード**枠を選ぶと全シーン解放で遊べる（進捗は実スロットと独立）。
10. 全ワールドをクリアするとホームに **Normal / Hard トグル**が出る。Hard では宝が小さく・数が増え・周期的に点滅する。消失中の宝のタップは無反応。
11. 設定で English に切替 → UI が英語化し、再起動後も保持（言語は全スロット共通）。
12. 設定の**「なぞった ときの いろ」**で色を選ぶ → Easy のなぞりキラキラがその色になる。再起動後も保持（色は全スロット共通）。

---

## 4. 接続実機へのインストール（Claude 実行用の手順・ルール）

> このセクションは **Claude 自身が USB 接続中の実機へインストールするときの実行ルール**。
> コマンド・既知デバイス ID・ハマりどころの回避策をまとめる。素の `flutter` は使わず
> **必ず `fvm flutter`** を使う（§1）。実機 ID が変わっていないかは毎回 `fvm flutter devices` で確認。

### 既知のデバイス

| 端末 | モデル / OS | デバイス ID | 署名 |
|---|---|---|---|
| Samsung Galaxy Tab S10 FE | SM-X520 / Android 16 | `R52Y60AQF8Y` | release は debug 鍵（keystore 不要） |
| iPad（linne-ipad） | iOS 26.5 | `00008112-001248E00CD8A01E` | Xcode の Team 署名（無料 Apple ID は約 7 日で失効 → 再インストールで復活） |

接続確認:

```bash
fvm flutter devices          # ID が上表と一致するか確認
adb devices                  # Android が出ない場合は下記「Auto Blocker」を疑う
```

### Android（Galaxy Tab）— ビルド先行 → install

**重要**: Android では `fvm flutter install` は APK を自動ビルドしない
（`app-release.apk does not exist` で失敗する）。**必ず先に build → install** の 2 段で実行する。

```bash
fvm flutter build apk --release
fvm flutter install --release -d R52Y60AQF8Y
```

`adb devices` が空 / 端末が MTP としてしか見えない場合（Samsung One UI 6.1+ の **Auto Blocker** が
USB デバッグを強制 OFF にしている）:

1. 端末: 設定 → セキュリティとプライバシー → 自動ブロッカー → **オフ**
2. 設定 → 開発者向けオプション → **USB デバッグ ON**
3. USB 再接続 → 「この PC を許可しますか?」を**許可**
4. `adb devices` に `R52Y60AQF8Y` が出たら上記 install を実行

### iPad — install 1 コマンド（ただし排他に注意）

iOS は `install` がビルドまで一括で行うので 1 コマンドで足りる:

```bash
fvm flutter install --release -d 00008112-001248E00CD8A01E
```

**ハマりどころ**: `"Uninstalling old version..."` で止まる場合、原因はほぼ
**残った `flutter run` プロセスが iPad を掴んだまま**（CoreDevice / `devicectl` は 1 デバイス 1 セッション）。

```bash
ps -ax | grep "flutter_tools.snapshot run"   # 残プロセスを特定
kill <pid>                                    # 掴んでいるプロセスを終了
fvm flutter install --release -d 00008112-001248E00CD8A01E   # 再実行
```

署名で失敗するときは `open ios/Runner.xcworkspace` → Signing & Capabilities で Team を再設定
（無料 Apple ID の証明書失効時はこれで復活）。端末側「設定 → 一般 → VPN とデバイス管理」で開発者を信頼。

---

## 5. テスト・静的解析・フォーマット

```bash
bash scripts/check.sh        # format(--set-exit-if-changed) + analyze + test を一括（推奨）

# 個別に
fvm dart format .
fvm flutter analyze          # always_use_package_imports 等のルールを含む
fvm flutter test
fvm flutter test test/unit/seek_find_logic_test.dart   # ファイル指定
```

- テスト方針は `.claude/rules/dart/testing.md` に準拠（Unit は純ロジック/Repository、
  Widget は意味のある挙動）。
- `shared_preferences` のテストは `SharedPreferences.setMockInitialValues` を使う。
- **`seek_find_screen` の widget テストは skip 済み**（`FoundBurst` アニメ + `rootBundle` +
  ジェスチャが flutter_test 上で相互干渉し、複数同時実行でハングするため）。発見ロジックは
  `seek_find_logic_test.dart`（`findHitTargetId`）で担保し、画面のタップ/なぞり/完了は
  上記「手動確認」で実機検証する。CI ではテストを実行していない（CI は配布のみ）。

---

## 5. Firebase App Distribution（Android 配布）

ワークフロー: `.github/workflows/distribute.yml`（`workflow_dispatch` 手動）。
`g-runner-flutter` を参考にした構成。release APK は `android/app/build.gradle.kts` の既定で
**debug 鍵署名**（専用 keystore 不要。テスター配布はこれで可）。

> アプリに Firebase ランタイム SDK は組み込まない。CI がサービスアカウント + App ID で APK を
> アップロードするだけなので、`google-services.json` も不要（Kids 規制のデータ収集ゼロを維持）。

### 初期セットアップ（一度だけ）

1. Firebase コンソールでプロジェクト作成 →「アプリを追加 > Android」、パッケージ名
   `com.linnefromice.kidsapp_treasurehunt` を登録 → **App ID**（`1:xxxx:android:yyyy`）を取得。
2. Google Cloud > IAM > サービスアカウント作成 → ロール **「Firebase App Distribution 管理者」** →
   JSON 鍵を作成・ダウンロード。
3. GitHub: リポジトリ > Settings > Secrets and variables > Actions に登録:
   - `FIREBASE_APP_ID` = 手順 1 の App ID
   - `FIREBASE_SERVICE_ACCOUNT_KEY` = 手順 2 の JSON **全文**
4. Firebase コンソール > App Distribution でテスターグループ `internal-testers` を作成、
   テスターのメールを追加。

### 配布の実行

- GitHub の Actions タブ >「Distribute (Android)」> Run workflow
- または `gh workflow run "Distribute (Android)"`
- `main` push で自動配布したい場合は `distribute.yml` の `push: branches: [main]` を有効化。

### CI を使わずローカルから配布（任意）

```bash
npm i -g firebase-tools && firebase login
fvm flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_APP_ID> --groups internal-testers
```

---

## 6. 厳守事項（Kids 規制）

ライブラリ・SDK を追加する前に必ず確認する（詳細は `README.md` §6）:

- **絶対に入れない**: Firebase Analytics / Crashlytics、行動広告 SDK（AdMob 行動広告・
  AppsFlyer・Adjust・Facebook SDK）、位置情報（Google Maps 等）。
- 設計原則: 行動広告 SDK ゼロ・データ収集ゼロ・保護者ゲートを MVP に含める。

---

## 7. バージョン更新（fvm）

```bash
fvm releases                 # 利用可能な版
fvm use <version>            # .fvmrc を更新（SDK 未取得なら自動インストール）
fvm flutter pub get
bash scripts/check.sh        # 全テスト緑を確認してからコミット
```

`.fvmrc` を変えれば CI（`flutter-version-file: .fvmrc`）も自動追従する。
`.fvm/`（SDK シンボリックリンク）は gitignore、`.fvmrc` はコミットする。
