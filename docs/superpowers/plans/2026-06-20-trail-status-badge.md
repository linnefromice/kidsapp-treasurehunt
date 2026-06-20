# トレイル色ステータスバッジ & アバター表示 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `TreasureMapScreen` の AppBar に「現在のトレイル色」バッジとアクティブスロットのアバター絵文字を追加し、ひと目で設定状態がわかるようにする。

**Architecture:** `treasure_map_screen.dart` 1 ファイルのみを変更。Leading の人アイコンをアバター絵文字に差し替え、Actions に新規プライベートウィジェット `_TrailBadge` を追加する（設定ボタンの左隣）。既存プロバイダーを watch するだけで外部変更ゼロ。

**Tech Stack:** Flutter / Riverpod (`trailSettingControllerProvider`, `saveSlotControllerProvider`, `activeSlotProvider`) / go_router

## Global Constraints

- Flutter 3.44.2 / Dart 3.12.2（`.fvmrc` 準拠）。ビルドコマンドは `fvm flutter ...`
- `fvm flutter` を使い素の `flutter` は叩かない
- 子供向け UX: タップターゲット最小 60×60 dp
- `package:` import のみ（相対 import 禁止）
- `dart format` / `flutter analyze` / `flutter test` を全通しで確認（`bash scripts/check.sh`）
- 新規パッケージ追加禁止
- コミットは Conventional Commits 形式 (`feat:` / `test:` / `chore:`)

---

## ファイルマップ

| 操作 | ファイル | 内容 |
|------|---------|------|
| Modify | `lib/features/treasure_map/treasure_map_screen.dart` | Leading 差し替え・`_TrailBadge` 追加・`_TrailDot` ヘルパー追加 |
| Modify | `test/widget/treasure_map_screen_test.dart` | バッジ・アバターの Widget テスト追加 |

---

## Task 1: Widget テストを先に書く（TDD の RED フェーズ）

**Files:**
- Modify: `test/widget/treasure_map_screen_test.dart`

**Interfaces:**
- Produces: テスト 4 本（後の Task 2 の実装対象を確定させる）
  - `ValueKey('trail-badge')` — `_TrailBadge` のルートに付ける Key
  - `ValueKey('avatar-button')` — Leading の GestureDetector/IconButton に付ける Key

- [ ] **Step 1: 既存の `_pumpHome` ヘルパーを理解したうえでテストを追加**

`test/widget/treasure_map_screen_test.dart` のファイル末尾（`}` の直前）に以下グループを追記する。  
`_pumpHome` のシグネチャは変えない。`seed` に `trail_style_id` 等の設定キーを追加で渡せる。

```dart
  group('trail badge', () {
    testWidgets('solid style — badge key exists', (tester) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': ['scene01'],
        'settings.trail_style_id': 'solid',
        'settings.trail_color_id': 'sky',
      });
      expect(find.byKey(const ValueKey('trail-badge')), findsOneWidget);
    });

    testWidgets('rainbow3 style — badge key exists', (tester) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': ['scene01'],
        'settings.trail_style_id': 'rainbow3',
        // rainbow3 は本来ロック中だが、設定リポジトリは unlock フラグとは独立して
        // 保存された style id を読み込むため、ここでは表示テストに絞る。
        'settings.trail_style_unlocked.rainbow3': true,
      });
      expect(find.byKey(const ValueKey('trail-badge')), findsOneWidget);
    });

    testWidgets('rainbowFull style — badge key exists', (tester) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': ['scene01'],
        'settings.trail_style_id': 'rainbowFull',
        'settings.trail_style_unlocked.rainbowFull': true,
      });
      expect(find.byKey(const ValueKey('trail-badge')), findsOneWidget);
    });
  });

  group('avatar button', () {
    testWidgets('slot with avatar shows emoji instead of person icon', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'progress.slot1.unlockedSceneIds': ['scene01'],
        'save_slots.created': ['slot1'],
        'save_slots.slot1.avatar': '🐱',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      container.read(saveSlotControllerProvider); // initialize
      container.read(activeSlotProvider.notifier).select('slot1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TreasureMapScreen()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('avatar-button')), findsOneWidget);
      expect(find.text('🐱'), findsOneWidget);
      // 人アイコンは出ない。
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('avatar-button')),
          matching: find.byIcon(Icons.person),
        ),
        findsNothing,
      );
    });

    testWidgets('slot without avatar falls back to person icon', (
      tester,
    ) async {
      await _pumpHome(tester, {
        'progress.slot1.unlockedSceneIds': ['scene01'],
        // avatar キーなし → saveSlotControllerProvider は空 Map を返す
      });

      expect(find.byKey(const ValueKey('avatar-button')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('avatar-button')),
          matching: find.byIcon(Icons.person),
        ),
        findsOneWidget,
      );
    });
  });
```

- [ ] **Step 2: テストが RED になることを確認**

```bash
fvm flutter test test/widget/treasure_map_screen_test.dart --no-pub 2>&1 | tail -30
```

Expected: 追加した 5 本のテストが `FAIL` または `Error`（`ValueKey('trail-badge')` 等が存在しないため）。既存テストは引き続き PASS。

- [ ] **Step 3: コミット（RED 状態のまま）**

```bash
git add test/widget/treasure_map_screen_test.dart
git commit -m "test: トレイルバッジ・アバターボタンの failing widget テストを追加"
```

---

## Task 2: `_TrailBadge` ウィジェットと Leading 差し替えを実装（GREEN フェーズ）

**Files:**
- Modify: `lib/features/treasure_map/treasure_map_screen.dart`

**Interfaces:**
- Consumes: Task 1 で確定したキー (`ValueKey('trail-badge')`, `ValueKey('avatar-button')`)
- Consumes: `trailSettingControllerProvider` → `TrailSetting`（`trail_color.dart` で定義）
- Consumes: `saveSlotControllerProvider` → `Map<String, String>`（slotId → 絵文字）
- Consumes: `activeSlotProvider` → `String?`（現在の slotId）
- Consumes: `kFreeModeSlotId`（`save_slots_catalog.dart`）

**Produces:**（Task 1 のテストが期待するもの）
- `_TrailBadge({required TrailSetting setting, required VoidCallback onTap})` — `ValueKey('trail-badge')`
- Leading の `IconButton` に `ValueKey('avatar-button')`

- [ ] **Step 4: `treasure_map_screen.dart` に import を追加する**

ファイル冒頭の import ブロックに以下を追記する（既存の import は変えない）：

```dart
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
```

- [ ] **Step 5: `_TreasureMapScreenState.build()` でプロバイダーを追加 watch する**

`build()` 内の既存の watch の後に以下を追記する：

```dart
    final trail = ref.watch(trailSettingControllerProvider);
    final activeSlotId = ref.watch(activeSlotProvider);
    final slots = ref.watch(saveSlotControllerProvider);
    final avatarEmoji = (activeSlotId != null && activeSlotId != kFreeModeSlotId)
        ? slots[activeSlotId]
        : null;
```

- [ ] **Step 6: AppBar の Leading を差し替える**

既存の `leading: IconButton(icon: const Icon(Icons.person), ...)` を以下で置き換える：

```dart
        leading: IconButton(
          key: const ValueKey('avatar-button'),
          icon: avatarEmoji != null
              ? Text(avatarEmoji, style: const TextStyle(fontSize: 28))
              : const Icon(Icons.person),
          onPressed: () {
            ref.read(activeSlotProvider.notifier).deselect();
            context.go('/slots');
          },
        ),
```

- [ ] **Step 7: AppBar の Actions に `_TrailBadge` を追加する**

既存の `actions:` リストに、設定 `IconButton` の **直前** に `_TrailBadge` を差し込む：

```dart
          _TrailBadge(
            setting: trail,
            onTap: () => context.go('/settings'),
          ),
```

つまり `actions:` は以下の順になる：

```dart
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${tr(localeCode, 'home.cleared')} '
                '${clearedForMode.length}/${kSceneCatalog.length} '
                '${isHard ? '🏆🔥' : '🏆'}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          _TrailBadge(
            setting: trail,
            onTap: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
```

- [ ] **Step 8: `_TrailBadge` ウィジェットを追加する**

ファイル末尾（最後の `}` の前）に以下を追記する：

```dart
/// AppBar に表示する現在のトレイルスタイルバッジ。タップで設定画面へ。
class _TrailBadge extends StatelessWidget {
  const _TrailBadge({required this.setting, required this.onTap});

  final TrailSetting setting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'トレイル色設定',
      child: IconButton(
        key: const ValueKey('trail-badge'),
        // タップターゲット 60dp 以上（IconButton デフォルト 48dp を padding で補う）。
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
        onPressed: onTap,
        icon: switch (setting.style) {
          TrailStyle.solid => _TrailDot(color: setting.solidColor.baseColor),
          TrailStyle.rainbow3 => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                _TrailDot(color: setting.threeColors[i].baseColor, size: 14),
              ],
            ],
          ),
          TrailStyle.rainbowFull => Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

/// トレイルバッジ用の色付き丸。淡色でも埋もれないよう薄枠を付ける。
class _TrailDot extends StatelessWidget {
  const _TrailDot({required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
```

- [ ] **Step 9: `dart format` で整形する**

```bash
fvm dart format lib/features/treasure_map/treasure_map_screen.dart
```

Expected: 差分のみ整形。エラーなし。

- [ ] **Step 10: `flutter analyze` でエラーがないことを確認**

```bash
fvm flutter analyze lib/features/treasure_map/treasure_map_screen.dart 2>&1
```

Expected: `No issues found!` または warning ゼロ。

- [ ] **Step 11: テストが GREEN になることを確認**

```bash
fvm flutter test test/widget/treasure_map_screen_test.dart --no-pub 2>&1 | tail -30
```

Expected: 全テスト PASS（既存 + 新規 5 本）。

- [ ] **Step 12: 全テスト + 全チェックを通す**

```bash
bash scripts/check.sh
```

Expected: format → analyze → test 全通し。エラーなし。

- [ ] **Step 13: コミット**

```bash
git add lib/features/treasure_map/treasure_map_screen.dart
git commit -m "feat: マップ画面にトレイルバッジとアバター表示を追加"
```

---

## Task 3: 手動確認 & PR

**Files:**（コード変更なし）

- [ ] **Step 14: iPad に再インストールして手動確認**

```bash
fvm flutter build ios --release 2>&1 | tail -5
xcrun devicectl device install app --device 00008112-001248E00CD8A01E build/ios/iphoneos/Runner.app
```

確認項目：
- [ ] マップ画面の Leading にアバター絵文字が表示される
- [ ] フリーモード選択時は人アイコンにフォールバックする
- [ ] トレイルが `solid`（みずいろ）のとき、バッジが水色の丸 1 つ
- [ ] トレイルが `rainbow3` のとき、バッジが 3 つの丸
- [ ] トレイルが `rainbowFull` のとき、バッジが虹グラデーション丸
- [ ] バッジをタップすると設定画面に遷移する
- [ ] 設定でトレイル色を変えてマップに戻るとバッジが更新されている

- [ ] **Step 15: PR を作成する**

```bash
git checkout -b feat/trail-status-badge
git push -u origin feat/trail-status-badge
gh pr create \
  --title "feat: マップ画面にトレイル色バッジとアバター表示を追加" \
  --body "$(cat <<'EOF'
## Summary
- AppBar Leading の人アイコンをアクティブスロットのアバター絵文字に差し替え（フリーモード/未設定は人アイコンへフォールバック）
- AppBar Actions の設定ボタン左隣に `_TrailBadge` を追加（solid: 単色丸, rainbow3: 3色丸, rainbowFull: 虹グラデーション丸）
- バッジはタップで `/settings` に遷移

## Test plan
- [ ] `fvm flutter test test/widget/treasure_map_screen_test.dart` — 全テスト PASS
- [ ] `bash scripts/check.sh` — format / analyze / test 全通し
- [ ] iPad 実機でトレイルスタイル別バッジ表示を目視確認
EOF
)"
```
