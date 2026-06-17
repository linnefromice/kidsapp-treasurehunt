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

1. ホームに 3 枚のシーンカード（`scene01` 解放・他ロック）。
2. `scene01` タップ → シーン画面でピンチ拡大/パンできる。
3. 隠し位置をタップ → 印が出て図鑑が埋まる。空振りは何も起きない。
4. 3 個すべて発見 → 「みつけたね！」表示。ホームに戻ると `scene01` に ✓。
5. 設定で English に切替 → UI が英語化し、再起動後も保持。

---

## 4. テスト・静的解析・フォーマット

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
