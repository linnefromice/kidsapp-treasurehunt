# 宝探しアプリ 基盤スケルトン + Tap版プレイ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 子供向け宝探しアプリの「動く土台 + 1シーンを実際に遊べる Tap 版コアループ(探す→タップで見つける→図鑑に収納→コンプリート)」を Flutter で構築する。

**Architecture:** 3レイヤ(UI Widget → Riverpod Controller/Provider → shared_preferences Repository)。コアの隠しオブジェクト探しは純 Flutter(`InteractiveViewer` + シーン子要素上の `GestureDetector` の localPosition + `Rect.contains`)で実装し、ゲームエンジンは使わない。永続化は端末ローカルのみ(バックエンド無し)。

**Tech Stack:** Flutter / Riverpod(手動 Notifier・コード生成なし)/ go_router / shared_preferences / audioplayers。

---

## 設計判断: spec からの MVP 簡素化(plan レビューで要確認)

approved spec を、最初のスライスを最短で動かすため以下の点だけ簡素化する。いずれも後で
spec 通りへ戻せる(上位レイヤ不変)。違和感があれば実装着手前に指摘してほしい。

1. **Riverpod はコード生成を使わない**(`@riverpod` + build_runner ではなく手動 `Notifier`/`Provider`)。
   build_runner の生成ステップを省き、TDD の反復を軽くするため。
2. **座標変換は `Matrix4` 逆行列を手書きしない**。シーン子要素に置いた `GestureDetector` の
   `details.localPosition` が(InteractiveViewer の変換適用後の)シーン座標になるため、それを
   正規化して `Rect.contains` で判定する。spec §2.3 の意図(タップ→正規化→Rect.contains)は不変。
3. **ローカライズは intl/ARB の gen-l10n を使わず**、`ja`/`en` の文字列 Map(`Strings`)で行う。
4. **シーン背景は本物のイラストではなくグラデーションのプレースホルダ**(`imageAsset` はモデルに残す)。
   実アートは後で差し替え。
5. **効果音は生成した無音WAVのプレースホルダ**(再生は try/catch で保護)。実 CC0 音源は後で差し替え。

共通定数: シーンの論理サイズ `kSceneSize = Size(800, 600)`(既定テストビューポートに収まり、初期
変換=恒等のときタップ座標=シーン座標になりテスト容易)。先頭シーン `kFirstSceneId = 'scene01'`。

---

## ファイル構成(責務マップ)

```
pubspec.yaml                         # 依存・assets 宣言
analysis_options.yaml                # flutter_lints
scripts/check.sh                     # format + analyze + test(ローカル)
.github/workflows/distribute.yml     # 手動配布(Firebase App Distribution / Android)
assets/
  scenes/scene01.json                # SceneDef(隠し宝の正規化Rect)
  sfx/found.wav, sfx/complete.wav    # プレースホルダ無音
lib/
  main.dart                          # SharedPreferences ロード + ProviderScope + 初期解放
  app.dart                           # MaterialApp.router + KidsTheme + locale
  router.dart                        # go_router: / , /hunt/:sceneId , /settings
  providers.dart                     # prefs/repos/audio/locale/found/scene の Provider 群
  scenes_catalog.dart                # ホームに並べるシーン一覧(id, titleKey)
  features/
    seek_find/
      seek_find_screen.dart          # InteractiveViewer + シーン + 図鑑 + 完了
      seek_find_logic.dart           # findHitTargetId(純Dart・テスト対象)
      models/find_target.dart
      models/scene_def.dart
      widgets/collection_bar.dart    # 図鑑(下部 N 枠)
      widgets/found_burst.dart       # 発見ジュース(拡大+キラッ)
    treasure_map/
      treasure_map_screen.dart       # 宝の地図ホーム
    settings/
      settings_screen.dart           # 言語切替 + 保護者ゲート入口 stub
  data/
    progress_repository.dart
    settings_repository.dart
  shared/
    audio/audio_service.dart         # interface + AudioPlayers実装 + 無音実装
    strings/strings.dart             # ja/en 文字列 + tr()
    widgets/kids_button.dart
    widgets/parental_gate.dart       # 入口 stub
    theme/kids_theme.dart
    theme/breakpoints.dart
test/
  unit/seek_find_logic_test.dart
  unit/scene_def_test.dart
  unit/progress_repository_test.dart
  unit/settings_repository_test.dart
  widget/kids_button_test.dart
  widget/collection_bar_test.dart
  widget/seek_find_screen_test.dart
  widget/treasure_map_screen_test.dart
  widget/settings_screen_test.dart
  widget/app_boot_test.dart
```

---

## Task 1: Flutter プロジェクト雛形 + 依存 + lint + チェックスクリプト

**Files:**
- Create: プロジェクト全体(`flutter create`)
- Modify: `pubspec.yaml`, `analysis_options.yaml`
- Create: `scripts/check.sh`

- [ ] **Step 1: 現在地でアプリ雛形を生成**

Run(リポジトリ直下で実行。`.` 指定で既存 README/docs を保持):
```bash
flutter create --org com.linnefromice --project-name kidsapp_treasurehunt --platforms=android,ios .
```
Expected: `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`, `test/` が生成される。

- [ ] **Step 2: 既定テストを走らせて土台を確認**

Run: `flutter test`
Expected: 生成された `test/widget_test.dart` が PASS(1 test)。

- [ ] **Step 3: 依存を追加(pubspec.yaml の dependencies / dev_dependencies を以下に置換)**

`pubspec.yaml` の `dependencies:` と `dev_dependencies:` ブロックを次に差し替える:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.0
  shared_preferences: ^2.3.3
  audioplayers: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

- [ ] **Step 4: assets 宣言を追加(pubspec.yaml の `flutter:` ブロック)**

`flutter:` ブロックを次にする:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/scenes/
    - assets/sfx/
```

- [ ] **Step 5: 依存を取得**

Run: `flutter pub get`
Expected: `Got dependencies!`(解決に失敗する場合のみ各パッケージを最新へ: `flutter pub upgrade`)。

- [ ] **Step 6: lint を有効化(analysis_options.yaml を置換)**

`analysis_options.yaml` を次にする:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
```

- [ ] **Step 7: ローカルチェックスクリプトを作成**

Create `scripts/check.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

- [ ] **Step 8: 実行権限を付与してプレースホルダ assets を用意**

Run:
```bash
chmod +x scripts/check.sh
mkdir -p assets/scenes assets/sfx
python3 - <<'PY'
import wave
for name in ('found', 'complete'):
    w = wave.open(f'assets/sfx/{name}.wav', 'w')
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
    w.writeframes(b'\x00\x00' * 2205)  # ~0.1s silence
    w.close()
PY
```
Expected: `assets/sfx/found.wav` と `assets/sfx/complete.wav` が生成される(有効な無音WAV)。

- [ ] **Step 9: コミット**

```bash
git add -A
git commit -m "chore: scaffold Flutter app with riverpod/go_router/prefs/audioplayers"
```

---

## Task 2: データモデル(FindTarget / SceneDef)

**Files:**
- Create: `lib/features/seek_find/models/find_target.dart`
- Create: `lib/features/seek_find/models/scene_def.dart`
- Test: `test/unit/scene_def_test.dart`
- Create: `assets/scenes/scene01.json`

- [ ] **Step 1: シーン定義 JSON を作成**

Create `assets/scenes/scene01.json`:
```json
{
  "id": "scene01",
  "titleKey": "scene.scene01.title",
  "imageAsset": "assets/scenes/scene01.png",
  "targets": [
    { "id": "apple", "labelKey": "target.apple", "left": 0.10, "top": 0.15, "width": 0.14, "height": 0.18 },
    { "id": "duck",  "labelKey": "target.duck",  "left": 0.60, "top": 0.30, "width": 0.14, "height": 0.18 },
    { "id": "star",  "labelKey": "target.star",  "left": 0.40, "top": 0.68, "width": 0.14, "height": 0.18 }
  ]
}
```

- [ ] **Step 2: 失敗するテストを書く**

Create `test/unit/scene_def_test.dart`:
```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';

void main() {
  test('SceneDef.fromJson parses targets into normalized rects', () {
    final scene = SceneDef.fromJson(const {
      'id': 'scene01',
      'titleKey': 'scene.scene01.title',
      'imageAsset': 'assets/scenes/scene01.png',
      'targets': [
        {'id': 'apple', 'labelKey': 'target.apple', 'left': 0.1, 'top': 0.2, 'width': 0.3, 'height': 0.4},
      ],
    });

    expect(scene.id, 'scene01');
    expect(scene.targets, hasLength(1));
    final FindTarget t = scene.targets.single;
    expect(t.id, 'apple');
    expect(t.normalizedRect, const Rect.fromLTWH(0.1, 0.2, 0.3, 0.4));
  });
}
```

- [ ] **Step 3: テストが失敗することを確認**

Run: `flutter test test/unit/scene_def_test.dart`
Expected: FAIL(`Target of URI doesn't exist` / 型未定義)。

- [ ] **Step 4: FindTarget を実装**

Create `lib/features/seek_find/models/find_target.dart`:
```dart
import 'dart:ui';

/// 隠し宝1つ。座標は 0.0〜1.0 の正規化値で持つ。
class FindTarget {
  const FindTarget({
    required this.id,
    required this.labelKey,
    required this.normalizedRect,
  });

  final String id;
  final String labelKey;
  final Rect normalizedRect;

  factory FindTarget.fromJson(Map<String, dynamic> json) {
    return FindTarget(
      id: json['id'] as String,
      labelKey: json['labelKey'] as String,
      normalizedRect: Rect.fromLTWH(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
    );
  }
}
```

- [ ] **Step 5: SceneDef を実装**

Create `lib/features/seek_find/models/scene_def.dart`:
```dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'find_target.dart';

/// 1シーンの定義(背景 + 隠し宝のリスト)。
class SceneDef {
  const SceneDef({
    required this.id,
    required this.titleKey,
    required this.imageAsset,
    required this.targets,
  });

  final String id;
  final String titleKey;
  final String imageAsset;
  final List<FindTarget> targets;

  factory SceneDef.fromJson(Map<String, dynamic> json) {
    return SceneDef(
      id: json['id'] as String,
      titleKey: json['titleKey'] as String,
      imageAsset: json['imageAsset'] as String,
      targets: (json['targets'] as List<dynamic>)
          .map((e) => FindTarget.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static Future<SceneDef> loadAsset(String sceneId) async {
    final raw = await rootBundle.loadString('assets/scenes/$sceneId.json');
    return SceneDef.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
```

- [ ] **Step 6: テストが通ることを確認**

Run: `flutter test test/unit/scene_def_test.dart`
Expected: PASS。

- [ ] **Step 7: コミット**

```bash
git add lib/features/seek_find/models test/unit/scene_def_test.dart assets/scenes/scene01.json
git commit -m "feat: add SceneDef/FindTarget models and scene01 definition"
```

---

## Task 3: ヒット判定ロジック(純Dart)

**Files:**
- Create: `lib/features/seek_find/seek_find_logic.dart`
- Test: `test/unit/seek_find_logic_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/seek_find_logic_test.dart`:
```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';

const _targets = [
  FindTarget(id: 'a', labelKey: 'target.a', normalizedRect: Rect.fromLTWH(0.0, 0.0, 0.2, 0.2)),
  FindTarget(id: 'b', labelKey: 'target.b', normalizedRect: Rect.fromLTWH(0.5, 0.5, 0.2, 0.2)),
];

void main() {
  const sceneSize = Size(800, 600);

  test('returns the target id when tap falls inside its rect', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60), // -> normalized (0.1, 0.1) inside 'a'
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, 'a');
  });

  test('returns null when tap is on empty space', () {
    final id = findHitTargetId(
      scenePoint: const Offset(720, 60), // normalized (0.9, 0.1) -> empty
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, isNull);
  });

  test('skips already-found targets', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60),
      sceneSize: sceneSize,
      targets: _targets,
      foundIds: const {'a'},
    );
    expect(id, isNull);
  });

  test('returns null for non-positive scene size', () {
    final id = findHitTargetId(
      scenePoint: const Offset(80, 60),
      sceneSize: Size.zero,
      targets: _targets,
      foundIds: const {},
    );
    expect(id, isNull);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/unit/seek_find_logic_test.dart`
Expected: FAIL(`findHitTargetId` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/features/seek_find/seek_find_logic.dart`:
```dart
import 'dart:ui';

import 'models/find_target.dart';

/// シーン座標 [scenePoint](GestureDetector の localPosition)を正規化し、
/// まだ見つかっていない最初のヒット対象 id を返す。空振りは null。
String? findHitTargetId({
  required Offset scenePoint,
  required Size sceneSize,
  required List<FindTarget> targets,
  required Set<String> foundIds,
}) {
  if (sceneSize.width <= 0 || sceneSize.height <= 0) {
    return null;
  }
  final normalized = Offset(
    scenePoint.dx / sceneSize.width,
    scenePoint.dy / sceneSize.height,
  );
  for (final target in targets) {
    if (foundIds.contains(target.id)) {
      continue;
    }
    if (target.normalizedRect.contains(normalized)) {
      return target.id;
    }
  }
  return null;
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/unit/seek_find_logic_test.dart`
Expected: PASS(4 tests)。

- [ ] **Step 5: コミット**

```bash
git add lib/features/seek_find/seek_find_logic.dart test/unit/seek_find_logic_test.dart
git commit -m "feat: add findHitTargetId hit-test logic with tests"
```

---

## Task 4: ProgressRepository(shared_preferences)

**Files:**
- Create: `lib/data/progress_repository.dart`
- Test: `test/unit/progress_repository_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/progress_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

Future<ProgressRepository> _repo() async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ensureInitialUnlock unlocks first scene only when empty', () async {
    final repo = await _repo();
    await repo.ensureInitialUnlock('scene01');
    expect(repo.isUnlocked('scene01'), isTrue);
    expect(repo.isUnlocked('scene02'), isFalse);
  });

  test('ensureInitialUnlock does not overwrite existing unlocks', () async {
    SharedPreferences.setMockInitialValues({
      'progress.unlockedSceneIds': ['scene02'],
    });
    final repo = await _repo();
    await repo.ensureInitialUnlock('scene01');
    expect(repo.isUnlocked('scene02'), isTrue);
    expect(repo.isUnlocked('scene01'), isFalse);
  });

  test('markCleared records scene as cleared', () async {
    final repo = await _repo();
    expect(repo.isCleared('scene01'), isFalse);
    await repo.markCleared('scene01');
    expect(repo.isCleared('scene01'), isTrue);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/unit/progress_repository_test.dart`
Expected: FAIL(`ProgressRepository` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/data/progress_repository.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 進捗(解放/クリア)の永続化窓口。shared_preferences をここに隠蔽する。
class ProgressRepository {
  ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _unlockedKey = 'progress.unlockedSceneIds';
  static const _clearedKey = 'progress.clearedSceneIds';

  List<String> unlockedSceneIds() => _prefs.getStringList(_unlockedKey) ?? const [];
  List<String> clearedSceneIds() => _prefs.getStringList(_clearedKey) ?? const [];

  bool isUnlocked(String sceneId) => unlockedSceneIds().contains(sceneId);
  bool isCleared(String sceneId) => clearedSceneIds().contains(sceneId);

  Future<void> ensureInitialUnlock(String firstSceneId) async {
    if (unlockedSceneIds().isEmpty) {
      await _prefs.setStringList(_unlockedKey, [firstSceneId]);
    }
  }

  Future<void> unlock(String sceneId) async {
    final next = unlockedSceneIds().toSet()..add(sceneId);
    await _prefs.setStringList(_unlockedKey, next.toList());
  }

  Future<void> markCleared(String sceneId) async {
    final next = clearedSceneIds().toSet()..add(sceneId);
    await _prefs.setStringList(_clearedKey, next.toList());
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/unit/progress_repository_test.dart`
Expected: PASS(3 tests)。

- [ ] **Step 5: コミット**

```bash
git add lib/data/progress_repository.dart test/unit/progress_repository_test.dart
git commit -m "feat: add ProgressRepository backed by shared_preferences"
```

---

## Task 5: SettingsRepository(言語)

**Files:**
- Create: `lib/data/settings_repository.dart`
- Test: `test/unit/settings_repository_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/settings_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to ja', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.localeCode(), 'ja');
  });

  test('persists locale code', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    await repo.setLocaleCode('en');
    expect(repo.localeCode(), 'en');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/unit/settings_repository_test.dart`
Expected: FAIL(`SettingsRepository` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/data/settings_repository.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 設定(表示言語)の永続化窓口。
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'settings.locale';

  String localeCode() => _prefs.getString(_localeKey) ?? 'ja';

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/unit/settings_repository_test.dart`
Expected: PASS(2 tests)。

- [ ] **Step 5: コミット**

```bash
git add lib/data/settings_repository.dart test/unit/settings_repository_test.dart
git commit -m "feat: add SettingsRepository for locale persistence"
```

---

## Task 6: ローカライズ(Strings + tr)

**Files:**
- Create: `lib/shared/strings/strings.dart`
- Test: `test/unit/strings_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/strings_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

void main() {
  test('resolves localized string', () {
    expect(tr('ja', 'home.title'), 'たからの ちず');
    expect(tr('en', 'home.title'), 'Treasure Map');
  });

  test('falls back to ja then key for unknown', () {
    expect(tr('en', 'definitely.missing'), 'definitely.missing');
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/unit/strings_test.dart`
Expected: FAIL(`tr` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/shared/strings/strings.dart`:
```dart
const Map<String, Map<String, String>> _strings = {
  'ja': {
    'app.title': 'たからさがし',
    'home.title': 'たからの ちず',
    'home.locked': 'ロック',
    'home.cleared': 'クリア',
    'settings.title': 'せってい',
    'settings.language': 'ことば',
    'seek.complete': 'みつけたね！',
    'scene.scene01.title': 'もりの たからさがし',
    'scene.scene02.title': 'うみの たからさがし',
    'scene.scene03.title': 'そらの たからさがし',
    'target.apple': 'りんご',
    'target.duck': 'あひる',
    'target.star': 'ほし',
  },
  'en': {
    'app.title': 'Treasure Hunt',
    'home.title': 'Treasure Map',
    'home.locked': 'Locked',
    'home.cleared': 'Cleared',
    'settings.title': 'Settings',
    'settings.language': 'Language',
    'seek.complete': 'You found them all!',
    'scene.scene01.title': 'Forest Hunt',
    'scene.scene02.title': 'Ocean Hunt',
    'scene.scene03.title': 'Sky Hunt',
    'target.apple': 'Apple',
    'target.duck': 'Duck',
    'target.star': 'Star',
  },
};

/// localeCode('ja'|'en') と key から表示文字列を返す。未定義は ja → key の順でフォールバック。
String tr(String localeCode, String key) {
  return _strings[localeCode]?[key] ?? _strings['ja']?[key] ?? key;
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/unit/strings_test.dart`
Expected: PASS(2 tests)。

- [ ] **Step 5: コミット**

```bash
git add lib/shared/strings/strings.dart test/unit/strings_test.dart
git commit -m "feat: add minimal ja/en string lookup"
```

---

## Task 7: テーマ + ブレークポイント

**Files:**
- Create: `lib/shared/theme/kids_theme.dart`
- Create: `lib/shared/theme/breakpoints.dart`

- [ ] **Step 1: ブレークポイントを実装(ロジックのみ・テストは任意のため省略)**

Create `lib/shared/theme/breakpoints.dart`:
```dart
import 'package:flutter/widgets.dart';

/// タブレット横向きを第一級にするための簡易ブレークポイント。
class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tablet;
}
```

- [ ] **Step 2: テーマを実装**

Create `lib/shared/theme/kids_theme.dart`:
```dart
import 'package:flutter/material.dart';

/// 子供向けの明るく丸いテーマ。
class KidsTheme {
  const KidsTheme._();

  /// 子供向け最小タッチターゲット(dp)。
  static const double minTouchTarget = 60;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFA000),
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
  }
}
```

- [ ] **Step 3: 解析が通ることを確認**

Run: `flutter analyze lib/shared/theme`
Expected: `No issues found!`

- [ ] **Step 4: コミット**

```bash
git add lib/shared/theme
git commit -m "feat: add KidsTheme and Breakpoints"
```

---

## Task 8: KidsButton(最小タッチターゲット)

**Files:**
- Create: `lib/shared/widgets/kids_button.dart`
- Test: `test/widget/kids_button_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/kids_button_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

void main() {
  testWidgets('is at least 60x60 and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: KidsButton(
            label: 'GO',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    ));

    final size = tester.getSize(find.byType(KidsButton));
    expect(size.width, greaterThanOrEqualTo(60));
    expect(size.height, greaterThanOrEqualTo(60));

    await tester.tap(find.byType(KidsButton));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/widget/kids_button_test.dart`
Expected: FAIL(`KidsButton` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/shared/widgets/kids_button.dart`:
```dart
import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// 子供向けの大きな丸ボタン。最小 60x60 を保証する。
class KidsButton extends StatelessWidget {
  const KidsButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: KidsTheme.minTouchTarget,
        minHeight: KidsTheme.minTouchTarget,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/widget/kids_button_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
git add lib/shared/widgets/kids_button.dart test/widget/kids_button_test.dart
git commit -m "feat: add KidsButton with min touch target"
```

---

## Task 9: AudioService(interface + 実装 + 無音)

**Files:**
- Create: `lib/shared/audio/audio_service.dart`

- [ ] **Step 1: 実装(再生は副作用のため TDD ではなく直接実装・try/catch で保護)**

Create `lib/shared/audio/audio_service.dart`:
```dart
import 'package:audioplayers/audioplayers.dart';

/// 効果音再生の抽象。テストでは [SilentAudioService] を注入する。
abstract class AudioService {
  Future<void> playFound();
  Future<void> playComplete();
}

/// audioplayers 実装。アセット欠落や再生失敗で UI を止めないよう握りつぶす。
class AudioPlayersService implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _safePlay(String asset) async {
    try {
      await _player.play(AssetSource(asset));
    } catch (_) {
      // 失敗しても無視(プレースホルダ音源 / 未バンドル時)
    }
  }

  @override
  Future<void> playFound() => _safePlay('sfx/found.wav');

  @override
  Future<void> playComplete() => _safePlay('sfx/complete.wav');
}

/// テスト・無音環境用。
class SilentAudioService implements AudioService {
  @override
  Future<void> playFound() async {}

  @override
  Future<void> playComplete() async {}
}
```

- [ ] **Step 2: 解析が通ることを確認**

Run: `flutter analyze lib/shared/audio`
Expected: `No issues found!`

- [ ] **Step 3: コミット**

```bash
git add lib/shared/audio/audio_service.dart
git commit -m "feat: add AudioService (audioplayers + silent fake)"
```

---

## Task 10: シーンカタログ + Provider 群

**Files:**
- Create: `lib/scenes_catalog.dart`
- Create: `lib/providers.dart`
- Test: `test/unit/locale_controller_test.dart`

- [ ] **Step 1: シーンカタログを実装**

Create `lib/scenes_catalog.dart`:
```dart
/// ホームに並べるシーンの一覧(MVP は scene01 のみ遊べる)。
class SceneCatalogEntry {
  const SceneCatalogEntry(this.id, this.titleKey);
  final String id;
  final String titleKey;
}

const String kFirstSceneId = 'scene01';

const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry('scene01', 'scene.scene01.title'),
  SceneCatalogEntry('scene02', 'scene.scene02.title'),
  SceneCatalogEntry('scene03', 'scene.scene03.title'),
];
```

- [ ] **Step 2: 失敗するテストを書く(LocaleController)**

Create `test/unit/locale_controller_test.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('locale defaults to ja and updates + persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), const Locale('ja'));

    await container.read(localeControllerProvider.notifier).setLocale('en');
    expect(container.read(localeControllerProvider), const Locale('en'));
    expect(prefs.getString('settings.locale'), 'en');
  });
}
```

- [ ] **Step 3: テストが失敗することを確認**

Run: `flutter test test/unit/locale_controller_test.dart`
Expected: FAIL(`providers.dart` 未定義)。

- [ ] **Step 4: Provider 群を実装**

Create `lib/providers.dart`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/progress_repository.dart';
import 'data/settings_repository.dart';
import 'features/seek_find/models/scene_def.dart';
import 'shared/audio/audio_service.dart';

/// main で実インスタンスに override する。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final audioServiceProvider = Provider<AudioService>((ref) => AudioPlayersService());

/// シーン定義の非同期ロード(sceneId ごと)。
final sceneProvider = FutureProvider.family<SceneDef, String>(
  (ref, sceneId) => SceneDef.loadAsset(sceneId),
);

/// 表示言語。初期値は SettingsRepository から。
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.read(settingsRepositoryProvider).localeCode());

  Future<void> setLocale(String code) async {
    await ref.read(settingsRepositoryProvider).setLocaleCode(code);
    state = Locale(code);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// シーン内で見つけた宝の id 集合(sceneId ごと)。
class FoundController extends FamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String sceneId) => <String>{};

  void markFound(String targetId) {
    if (state.contains(targetId)) return;
    state = {...state, targetId};
  }
}

final foundControllerProvider =
    NotifierProvider.family<FoundController, Set<String>, String>(FoundController.new);
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/unit/locale_controller_test.dart`
Expected: PASS。

- [ ] **Step 6: コミット**

```bash
git add lib/scenes_catalog.dart lib/providers.dart test/unit/locale_controller_test.dart
git commit -m "feat: add scene catalog and riverpod providers"
```

---

## Task 11: CollectionBar(図鑑)

**Files:**
- Create: `lib/features/seek_find/widgets/collection_bar.dart`
- Test: `test/widget/collection_bar_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/collection_bar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';

void main() {
  testWidgets('renders one slot per target and marks found ones', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CollectionBar(
          targetIds: ['apple', 'duck', 'star'],
          foundIds: {'apple'},
        ),
      ),
    ));

    expect(find.byKey(const ValueKey('slot.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.duck')), findsNothing);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/widget/collection_bar_test.dart`
Expected: FAIL(`CollectionBar` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/features/seek_find/widgets/collection_bar.dart`:
```dart
import 'package:flutter/material.dart';

/// 画面下の図鑑。各 target に1枠、見つけたら埋まる。
class CollectionBar extends StatelessWidget {
  const CollectionBar({super.key, required this.targetIds, required this.foundIds});

  final List<String> targetIds;
  final Set<String> foundIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final id in targetIds)
            Padding(
              key: ValueKey('slot.$id'),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.brown, width: 3),
                  color: foundIds.contains(id) ? Colors.amber.shade200 : Colors.white,
                ),
                child: foundIds.contains(id)
                    ? Icon(Icons.star, key: ValueKey('found.$id'), color: Colors.amber.shade800, size: 36)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/widget/collection_bar_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
git add lib/features/seek_find/widgets/collection_bar.dart test/widget/collection_bar_test.dart
git commit -m "feat: add CollectionBar widget"
```

---

## Task 12: FoundBurst(発見ジュース演出)

**Files:**
- Create: `lib/features/seek_find/widgets/found_burst.dart`
- Test: `test/widget/found_burst_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/found_burst_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';

void main() {
  testWidgets('animates a found marker without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FoundBurst()),
    ));
    expect(find.byType(FoundBurst), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/widget/found_burst_test.dart`
Expected: FAIL(`FoundBurst` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/features/seek_find/widgets/found_burst.dart`:
```dart
import 'package:flutter/material.dart';

/// 発見した宝の位置に重ねる、拡大+フェードのキラッ演出。
class FoundBurst extends StatefulWidget {
  const FoundBurst({super.key});

  @override
  State<FoundBurst> createState() => _FoundBurstState();
}

class _FoundBurstState extends State<FoundBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1.2).animate(
        CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.9).animate(_c),
        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 56),
      ),
    );
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/widget/found_burst_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
git add lib/features/seek_find/widgets/found_burst.dart test/widget/found_burst_test.dart
git commit -m "feat: add FoundBurst juice animation"
```

---

## Task 13: SeekFindScreen(コアプレイ画面)

**Files:**
- Create: `lib/features/seek_find/seek_find_screen.dart`
- Test: `test/widget/seek_find_screen_test.dart`

シーンは `kSceneSize = Size(800, 600)` の `SizedBox` を `InteractiveViewer` の子にし、その子を
`GestureDetector(onTapDown)` で包む。初期変換は恒等なので、既定テストビューポート(800x600)では
タップの `localPosition` がそのままシーン座標になる。見つけた宝の位置には印を出し、全部見つけたら
完了処理(`markCleared` + 完了音 + 祝いオーバーレイ)を1回だけ走らせる。

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/seek_find_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/audio/audio_service.dart';

// scene01.json の target 正規化中心(left+width/2, top+height/2)。シーンローカル座標へは ×kSceneSize。
const _sceneCenters = {
  'apple': Offset((0.10 + 0.07) * 800, (0.15 + 0.09) * 600),
  'duck': Offset((0.60 + 0.07) * 800, (0.30 + 0.09) * 600),
  'star': Offset((0.40 + 0.07) * 800, (0.68 + 0.09) * 600),
};

Future<ProviderContainer> _pumpScene(WidgetTester tester) async {
  // シーン(800x600)が AppBar/図鑑の下に丸ごと収まるよう、テスト面を広げる。
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    audioServiceProvider.overrideWithValue(SilentAudioService()),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: SeekFindScreen(sceneId: 'scene01')),
  ));
  // FutureProvider(scene load)の解決を待つ
  await tester.pumpAndSettle();
  return container;
}

/// シーン要素の画面上の原点を基準に、目的のターゲット中心をグローバル座標へ変換してタップ。
Future<void> _tapTarget(WidgetTester tester, String id) async {
  final origin = tester.getTopLeft(find.byKey(const ValueKey('scene-content')));
  await tester.tapAt(origin + _sceneCenters[id]!);
  await tester.pump();
}

void main() {
  testWidgets('tapping a target fills its collection slot', (tester) async {
    await _pumpScene(tester);

    expect(find.byKey(const ValueKey('found.apple')), findsNothing);
    await _tapTarget(tester, 'apple');
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
  });

  testWidgets('finding all targets marks the scene cleared', (tester) async {
    final container = await _pumpScene(tester);

    for (final id in _sceneCenters.keys) {
      await _tapTarget(tester, id);
    }
    await tester.pumpAndSettle();

    final progress = container.read(progressRepositoryProvider);
    expect(progress.isCleared('scene01'), isTrue);
    expect(find.text('みつけたね！'), findsOneWidget);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/widget/seek_find_screen_test.dart`
Expected: FAIL(`SeekFindScreen` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/features/seek_find/seek_find_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/strings/strings.dart';
import 'models/scene_def.dart';
import 'seek_find_logic.dart';
import 'widgets/collection_bar.dart';
import 'widgets/found_burst.dart';

const Size kSceneSize = Size(800, 600);

class SeekFindScreen extends ConsumerWidget {
  const SeekFindScreen({super.key, required this.sceneId});

  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneAsync = ref.watch(sceneProvider(sceneId));
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).maybePop())),
      body: sceneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (scene) => _SceneView(scene: scene),
      ),
    );
  }
}

class _SceneView extends ConsumerStatefulWidget {
  const _SceneView({required this.scene});
  final SceneDef scene;

  @override
  ConsumerState<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends ConsumerState<_SceneView> {
  bool _completeHandled = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(scene.id));

    // 全発見 → 一度だけ完了処理
    if (found.length == scene.targets.length && !_completeHandled) {
      _completeHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(progressRepositoryProvider).markCleared(scene.id);
        await ref.read(audioServiceProvider).playComplete();
        if (mounted) setState(() {});
      });
    }

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details.localPosition, scene, found),
              child: SizedBox(
                key: const ValueKey('scene-content'),
                width: kSceneSize.width,
                height: kSceneSize.height,
                child: Stack(
                  children: [
                    // プレースホルダ背景(実アートは後で差し替え)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
                        ),
                      ),
                    ),
                    // 見つけた宝の位置に印 + バースト
                    for (final t in scene.targets)
                      if (found.contains(t.id))
                        Positioned(
                          left: t.normalizedRect.left * kSceneSize.width,
                          top: t.normalizedRect.top * kSceneSize.height,
                          width: t.normalizedRect.width * kSceneSize.width,
                          height: t.normalizedRect.height * kSceneSize.height,
                          child: const FoundBurst(),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        CollectionBar(
          targetIds: [for (final t in scene.targets) t.id],
          foundIds: found,
        ),
        if (_completeHandled)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr(localeCode, 'seek.complete'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  void _handleTap(Offset localPosition, SceneDef scene, Set<String> found) {
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: kSceneSize,
      targets: scene.targets,
      foundIds: found,
    );
    if (hitId == null) return; // 空振りは罰しない
    ref.read(foundControllerProvider(scene.id).notifier).markFound(hitId);
    ref.read(audioServiceProvider).playFound();
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/widget/seek_find_screen_test.dart`
Expected: PASS(2 tests)。

- [ ] **Step 5: コミット**

```bash
git add lib/features/seek_find/seek_find_screen.dart test/widget/seek_find_screen_test.dart
git commit -m "feat: add SeekFindScreen tap-to-find core loop"
```

---

## Task 14: TreasureMapScreen(宝の地図ホーム)

**Files:**
- Create: `lib/features/treasure_map/treasure_map_screen.dart`
- Test: `test/widget/treasure_map_screen_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/treasure_map_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('shows a card per scene; first unlocked, others locked', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.unlockedSceneIds': ['scene01']});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TreasureMapScreen()),
    ));

    expect(find.byKey(const ValueKey('scene-card.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-card.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('locked.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('locked.scene01')), findsNothing);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `flutter test test/widget/treasure_map_screen_test.dart`
Expected: FAIL(`TreasureMapScreen` 未定義)。

- [ ] **Step 3: 実装**

Create `lib/features/treasure_map/treasure_map_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../scenes_catalog.dart';
import '../../shared/strings/strings.dart';

class TreasureMapScreen extends ConsumerWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(localeCode, 'home.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final entry in kSceneCatalog)
            _SceneCard(
              entry: entry,
              localeCode: localeCode,
              unlocked: progress.isUnlocked(entry.id),
              cleared: progress.isCleared(entry.id),
              onTap: progress.isUnlocked(entry.id)
                  ? () => context.go('/hunt/${entry.id}')
                  : null,
            ),
        ],
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.entry,
    required this.localeCode,
    required this.unlocked,
    required this.cleared,
    required this.onTap,
  });

  final SceneCatalogEntry entry;
  final String localeCode;
  final bool unlocked;
  final bool cleared;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('scene-card.${entry.id}'),
      onTap: onTap,
      child: Card(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(tr(localeCode, entry.titleKey), textAlign: TextAlign.center),
            ),
            if (!unlocked)
              Icon(Icons.lock, key: ValueKey('locked.${entry.id}'), size: 40),
            if (cleared)
              const Positioned(top: 6, right: 6, child: Icon(Icons.check_circle, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: テストが通ることを確認**

Run: `flutter test test/widget/treasure_map_screen_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
git add lib/features/treasure_map/treasure_map_screen.dart test/widget/treasure_map_screen_test.dart
git commit -m "feat: add TreasureMapScreen home with lock/unlock"
```

---

## Task 15: SettingsScreen(言語切替 + 保護者ゲート入口 stub)

**Files:**
- Create: `lib/shared/widgets/parental_gate.dart`
- Create: `lib/features/settings/settings_screen.dart`
- Test: `test/widget/settings_screen_test.dart`

- [ ] **Step 1: 保護者ゲート入口 stub を実装**

Create `lib/shared/widgets/parental_gate.dart`:
```dart
import 'package:flutter/material.dart';

/// 保護者ゲートの入口 stub。MVP では確認ダイアログのみ(算数問題は後続spec)。
class ParentalGate {
  const ParentalGate._();

  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('おとなのひと へ'),
        content: const Text('このさきは おとなのひと と いっしょに。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('もどる')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    return ok ?? false;
  }
}
```

- [ ] **Step 2: 失敗するテストを書く**

Create `test/widget/settings_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/settings/settings_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('toggling to English persists locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ));

    await tester.tap(find.byKey(const ValueKey('lang.en')));
    await tester.pump();

    expect(container.read(localeControllerProvider).languageCode, 'en');
    expect(prefs.getString('settings.locale'), 'en');
  });
}
```

- [ ] **Step 3: テストが失敗することを確認**

Run: `flutter test test/widget/settings_screen_test.dart`
Expected: FAIL(`SettingsScreen` 未定義)。

- [ ] **Step 4: 実装**

Create `lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/strings/strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final controller = ref.read(localeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(tr(localeCode, 'settings.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr(localeCode, 'settings.language'), style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                key: const ValueKey('lang.ja'),
                label: const Text('にほんご'),
                selected: localeCode == 'ja',
                onSelected: (_) => controller.setLocale('ja'),
              ),
              ChoiceChip(
                key: const ValueKey('lang.en'),
                label: const Text('English'),
                selected: localeCode == 'en',
                onSelected: (_) => controller.setLocale('en'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: テストが通ることを確認**

Run: `flutter test test/widget/settings_screen_test.dart`
Expected: PASS。

- [ ] **Step 6: コミット**

```bash
git add lib/shared/widgets/parental_gate.dart lib/features/settings/settings_screen.dart test/widget/settings_screen_test.dart
git commit -m "feat: add SettingsScreen language toggle and parental gate stub"
```

---

## Task 16: ルーター + App + main 配線

**Files:**
- Create: `lib/router.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`(置換)
- Test: `test/widget/app_boot_test.dart`
- Modify: `test/widget_test.dart`(削除)

- [ ] **Step 1: 既定の雛形テストを削除(古い MyApp 参照のため)**

Run: `git rm test/widget_test.dart`
Expected: 削除される。

- [ ] **Step 2: ルーターを実装**

Create `lib/router.dart`:
```dart
import 'package:go_router/go_router.dart';

import 'features/seek_find/seek_find_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/treasure_map/treasure_map_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TreasureMapScreen()),
    GoRoute(
      path: '/hunt/:sceneId',
      builder: (context, state) => SeekFindScreen(sceneId: state.pathParameters['sceneId']!),
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);
```

- [ ] **Step 3: App を実装**

Create `lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'shared/strings/strings.dart';
import 'shared/theme/kids_theme.dart';

class TreasureHuntApp extends ConsumerWidget {
  const TreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: tr(locale.languageCode, 'app.title'),
      theme: KidsTheme.light(),
      locale: locale,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: main を置換**

Replace `lib/main.dart` の全内容:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/progress_repository.dart';
import 'providers.dart';
import 'scenes_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ProgressRepository(prefs).ensureInitialUnlock(kFirstSceneId);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TreasureHuntApp(),
    ),
  );
}
```

- [ ] **Step 5: 起動スモークテストを書く**

Create `test/widget/app_boot_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('boots to the treasure map home', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.unlockedSceneIds': ['scene01']});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TreasureHuntApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('たからの ちず'), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-card.scene01')), findsOneWidget);
  });
}
```

- [ ] **Step 6: テストが通ることを確認**

Run: `flutter test test/widget/app_boot_test.dart`
Expected: PASS。

- [ ] **Step 7: コミット**

```bash
git add lib/router.dart lib/app.dart lib/main.dart test/widget/app_boot_test.dart
git commit -m "feat: wire router, app, and main entrypoint"
```

---

## Task 17: 配布CI(GitHub Actions / Firebase App Distribution)

**Files:**
- Create: `.github/workflows/distribute.yml`

- [ ] **Step 1: ワークフローを作成**

Create `.github/workflows/distribute.yml`:
```yaml
name: Distribute (Android)

on:
  workflow_dispatch:

jobs:
  distribute-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get

      - run: flutter build apk --release

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: testers
          file: build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 2: YAML 妥当性を目視確認**

Run: `flutter analyze` は YAML を見ないため、`cat .github/workflows/distribute.yml` で字下げを確認。
Expected: `on: workflow_dispatch` と APK パス `build/app/outputs/flutter-apk/app-release.apk` が正しい。

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/distribute.yml
git commit -m "ci: add manual Firebase App Distribution workflow (Android APK)"
```

> 配布の前提(リポジトリ設定): GitHub Secrets に `FIREBASE_APP_ID` と `FIREBASE_SERVICE_ACCOUNT`
> (App Distribution 権限のサービスアカウント JSON 全文)を登録する。Firebase 側でテスターグループ
> `testers` を作成しておく。これらは実行前に手動で用意する。

---

## Task 18: 全体検証(Definition of Done)

**Files:** なし(検証のみ)

- [ ] **Step 1: フォーマットを適用**

Run: `dart format .`
Expected: 必要なら整形され、差分が出る。

- [ ] **Step 2: 静的解析**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 全テスト**

Run: `flutter test`
Expected: 全 PASS(unit + widget)。

- [ ] **Step 4: 実機/エミュレータで手動確認(DoD)**

Run: `flutter run`(Android タブレット or iPad)。確認項目:
1. ホームにシーンカード3枚(scene01=解放、他=ロック)。
2. scene01 を tap → シーン画面。ピンチ拡大/パンできる。
3. 隠し宝の位置をタップ → 印が出て図鑑が埋まる。空振りは何も起きない。
4. 3個すべて発見 → 「みつけたね！」表示。ホームに戻ると scene01 に ✓。
5. 設定で English に切替 → 表示が英語化、再起動後も英語。

- [ ] **Step 5: 整形差分があればコミット**

```bash
git add -A
git commit -m "style: apply dart format" || echo "nothing to format"
```

---

## Self-Review メモ(spec カバレッジ)

- spec §2 コアループ(探す→タップ→図鑑→コンプリート) → Task 13。
- spec §2.3 ヒット判定(正規化+Rect.contains) → Task 3(純Dart)+ Task 13(localPosition で取得)。
- spec §4.4 モデル → Task 2。§4.5 永続化キー → Task 4/5。
- spec §4.2 ディレクトリ/feature 分割 → 各 Task のファイルパス。
- spec §5 完成定義 → Task 18 の手動確認。
- spec §6 UX(最小タッチターゲット/失敗罰しない/保護者ゲート入口) → Task 8 / Task 13(空振り無反応) / Task 15。
- spec §7 CI(手動配布のみ) → Task 17。§7.2 ローカル check → Task 1。
- 図鑑/ジュース/音 → Task 11 / 12 / 9・13。
- 簡素化(codegen 無し・Matrix4 手書き無し・manual l10n・プレースホルダ assets)は冒頭「設計判断」に明記。
```
