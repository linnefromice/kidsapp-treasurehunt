# セーブスロット（3スロット）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 進捗を独立に持つ 3 つのセーブスロットを追加し、起動時に固定アバターの選択画面で選ぶ／作る／（保護者ゲート経由で）リセットできるようにする。

**Architecture:** 進捗の永続化キーを `progress.<slotId>.*` に名前空間化し、`activeSlotProvider`（選択中スロット）にスコープした `progressRepositoryProvider` を経由させることで既存画面（treasure_map / seek_find）を無改修に保つ。スロットのメタ情報（作成済み集合）は `SaveSlotRepository` + `saveSlotControllerProvider`。起動ルートを `/slots` にし、未選択なら redirect。

**Tech Stack:** Flutter 3.44.2（fvm）/ Riverpod（手動 Notifier）/ go_router / shared_preferences。コマンドは `fvm flutter ...`。プロジェクト内 import は `package:kidsapp_treasurehunt/...`（`always_use_package_imports` 有効）。

---

## 前提・注意

- 設計の正典: `docs/superpowers/specs/2026-06-17-save-slots-design.md`。
- **未リリースのため旧キー（`progress.unlockedSceneIds` など）からの移行は不要**。`progress.<slotId>.*` に置換する。
- `ProgressRepository` のコンストラクタ変更（slotId 追加）は providers / main / 既存テストへ波及するため、**Task 3 で関連を一括変更**してスイートを緑に戻す（Task 1・2 は additive で各々緑）。
- すべてのコミット後に少なくとも対象テストを実行。最終的に `bash scripts/check.sh`（fvm 経由の format+analyze+test）が緑であること。

## ファイル構成（このプランで触る範囲）

```
lib/
  save_slots_catalog.dart                 # 新規: SaveSlot + kSaveSlots
  data/save_slot_repository.dart          # 新規: 作成済みスロット集合
  data/progress_repository.dart           # 変更: slotId スコープ化 + clearAll
  providers.dart                          # 変更: activeSlot/saveSlot 系 + progressRepositoryProvider
  router.dart                             # 変更: routerProvider + /slots + redirect
  app.dart                                # 変更: ref.watch(routerProvider)
  main.dart                               # 変更: 起動時 ensureInitialUnlock 廃止
  features/save_slots/slot_select_screen.dart  # 新規
  shared/strings/strings.dart             # 変更: slot.* キー追加
test/
  unit/save_slot_repository_test.dart     # 新規
  unit/save_slot_controller_test.dart     # 新規
  unit/progress_repository_test.dart      # 変更: slotId 対応
  unit/strings_test.dart                  # 変更: slot.* 追加（任意）
  widget/slot_select_screen_test.dart     # 新規
  widget/app_boot_test.dart               # 変更: /slots 起動
  widget/treasure_map_screen_test.dart    # 変更: activeSlot 設定
  widget/seek_find_screen_test.dart       # 変更: activeSlot 設定
```

---

## Task 1: SaveSlot カタログ + SaveSlotRepository

**Files:**
- Create: `lib/save_slots_catalog.dart`
- Create: `lib/data/save_slot_repository.dart`
- Test: `test/unit/save_slot_repository_test.dart`

- [ ] **Step 1: カタログを作成**

Create `lib/save_slots_catalog.dart`:
```dart
import 'package:flutter/material.dart';

/// セーブスロットの静的定義（固定 3 枠・固定アバター。実画像は後で差し替え）。
class SaveSlot {
  const SaveSlot(this.id, this.avatar);
  final String id;
  final IconData avatar;
}

const List<SaveSlot> kSaveSlots = [
  SaveSlot('slot1', Icons.pets),
  SaveSlot('slot2', Icons.cruelty_free),
  SaveSlot('slot3', Icons.flutter_dash),
];
```

- [ ] **Step 2: 失敗するテストを書く**

Create `test/unit/save_slot_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('markCreated / removeCreated track slot ids', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SaveSlotRepository(prefs);

    expect(repo.isCreated('slot1'), isFalse);
    await repo.markCreated('slot1');
    expect(repo.isCreated('slot1'), isTrue);
    expect(repo.createdSlotIds(), ['slot1']);

    await repo.removeCreated('slot1');
    expect(repo.isCreated('slot1'), isFalse);
  });
}
```

- [ ] **Step 3: 失敗確認**

Run: `fvm flutter test test/unit/save_slot_repository_test.dart`
Expected: FAIL（`SaveSlotRepository` 未定義）。

- [ ] **Step 4: 実装**

Create `lib/data/save_slot_repository.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 「開始済み（作成済み）」のセーブスロット id 集合を永続化する。
class SaveSlotRepository {
  SaveSlotRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _createdKey = 'save.createdSlotIds';

  List<String> createdSlotIds() => _prefs.getStringList(_createdKey) ?? const [];

  bool isCreated(String slotId) => createdSlotIds().contains(slotId);

  Future<void> markCreated(String slotId) async {
    final next = createdSlotIds().toSet()..add(slotId);
    await _prefs.setStringList(_createdKey, next.toList());
  }

  Future<void> removeCreated(String slotId) async {
    final next = createdSlotIds().toSet()..remove(slotId);
    await _prefs.setStringList(_createdKey, next.toList());
  }
}
```

- [ ] **Step 5: 通過確認**

Run: `fvm flutter test test/unit/save_slot_repository_test.dart`
Expected: PASS。

- [ ] **Step 6: コミット**

```bash
fvm dart format lib/save_slots_catalog.dart lib/data/save_slot_repository.dart test/unit/save_slot_repository_test.dart
git add lib/save_slots_catalog.dart lib/data/save_slot_repository.dart test/unit/save_slot_repository_test.dart
git commit -m "feat: add SaveSlot catalog and SaveSlotRepository"
```

---

## Task 2: ローカライズ文字列（slot.*）

**Files:**
- Modify: `lib/shared/strings/strings.dart`
- Test: `test/unit/strings_test.dart`

- [ ] **Step 1: 失敗するテストを追記**

In `test/unit/strings_test.dart`, add inside `main()`:
```dart
  test('resolves slot strings', () {
    expect(tr('ja', 'slot.title'), 'だれが あそぶ?');
    expect(tr('en', 'slot.title'), 'Who is playing?');
    expect(tr('ja', 'slot.new'), 'あたらしく');
    expect(tr('ja', 'slot.continue'), 'つづき');
  });
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/unit/strings_test.dart`
Expected: FAIL（`slot.title` が key そのまま返る）。

- [ ] **Step 3: 文字列を追加**

In `lib/shared/strings/strings.dart`, add these entries to the `'ja'` map and `'en'` map respectively:

ja:
```dart
    'slot.title': 'だれが あそぶ?',
    'slot.new': 'あたらしく',
    'slot.continue': 'つづき',
    'slot.reset': 'リセット',
```
en:
```dart
    'slot.title': 'Who is playing?',
    'slot.new': 'New',
    'slot.continue': 'Continue',
    'slot.reset': 'Reset',
```

- [ ] **Step 4: 通過確認**

Run: `fvm flutter test test/unit/strings_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
fvm dart format lib/shared/strings/strings.dart test/unit/strings_test.dart
git add lib/shared/strings/strings.dart test/unit/strings_test.dart
git commit -m "feat: add slot.* localization strings"
```

---

## Task 3: スロットスコープ化（コア統合）

`ProgressRepository` を slotId スコープに変え、`activeSlotProvider` / `saveSlotControllerProvider` /
`progressRepositoryProvider`（アクティブスロット束縛）/ `SlotSelectScreen` / router / main を一括で
入れ替え、影響する既存テストを更新する。**この Task の終わりにスイート全体を緑に戻す。**

**Files:**
- Modify: `lib/data/progress_repository.dart`
- Modify: `lib/providers.dart`
- Create: `lib/features/save_slots/slot_select_screen.dart`
- Modify: `lib/router.dart`, `lib/app.dart`, `lib/main.dart`
- Test (new): `test/unit/save_slot_controller_test.dart`
- Test (update): `test/unit/progress_repository_test.dart`, `test/widget/app_boot_test.dart`, `test/widget/treasure_map_screen_test.dart`, `test/widget/seek_find_screen_test.dart`

- [ ] **Step 1: `ProgressRepository` を slot スコープ化**

Replace the entire contents of `lib/data/progress_repository.dart`:
```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 進捗（解放/クリア）の永続化窓口。セーブスロット単位でキーを名前空間化する。
class ProgressRepository {
  ProgressRepository(this._prefs, this._slotId);

  final SharedPreferences _prefs;
  final String _slotId;

  String get _unlockedKey => 'progress.$_slotId.unlockedSceneIds';
  String get _clearedKey => 'progress.$_slotId.clearedSceneIds';

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

  /// このスロットの進捗キーを削除する（リセット用）。
  Future<void> clearAll() async {
    await _prefs.remove(_unlockedKey);
    await _prefs.remove(_clearedKey);
  }
}
```

- [ ] **Step 2: providers を更新（activeSlot / saveSlot 系 + progressRepositoryProvider 差し替え）**

In `lib/providers.dart`:

(a) Add imports near the other internal imports:
```dart
import 'package:kidsapp_treasurehunt/data/save_slot_repository.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
```

(b) Replace the existing `progressRepositoryProvider` definition:
```dart
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);
```
with:
```dart
/// 現在選択中のセーブスロット id（未選択は null）。
class ActiveSlotController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String slotId) => state = slotId;
}

final activeSlotProvider =
    NotifierProvider<ActiveSlotController, String?>(ActiveSlotController.new);

final saveSlotRepositoryProvider = Provider<SaveSlotRepository>(
  (ref) => SaveSlotRepository(ref.watch(sharedPreferencesProvider)),
);

/// 作成済みスロット id 集合 + 生成/リセットのライフサイクル。
class SaveSlotController extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.read(saveSlotRepositoryProvider).createdSlotIds().toSet();

  Future<void> createSlot(String slotId) async {
    await ref.read(saveSlotRepositoryProvider).markCreated(slotId);
    await ProgressRepository(ref.read(sharedPreferencesProvider), slotId)
        .ensureInitialUnlock(kFirstSceneId);
    state = {...state, slotId};
  }

  Future<void> resetSlot(String slotId) async {
    await ref.read(saveSlotRepositoryProvider).removeCreated(slotId);
    await ProgressRepository(ref.read(sharedPreferencesProvider), slotId).clearAll();
    state = state.where((id) => id != slotId).toSet();
  }
}

final saveSlotControllerProvider =
    NotifierProvider<SaveSlotController, Set<String>>(SaveSlotController.new);

/// アクティブスロットにスコープした進捗 Repository。既存画面はこれを使うだけでよい。
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final slotId = ref.watch(activeSlotProvider);
  if (slotId == null) {
    throw StateError('No active save slot selected');
  }
  return ProgressRepository(ref.watch(sharedPreferencesProvider), slotId);
});
```

- [ ] **Step 3: `SlotSelectScreen` を作成**

Create `lib/features/save_slots/slot_select_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/parental_gate.dart';

class SlotSelectScreen extends ConsumerWidget {
  const SlotSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final created = ref.watch(saveSlotControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(localeCode, 'slot.title'))),
      body: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final slot in kSaveSlots)
              _SlotCard(
                slot: slot,
                localeCode: localeCode,
                isCreated: created.contains(slot.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({
    required this.slot,
    required this.localeCode,
    required this.isCreated,
  });

  final SaveSlot slot;
  final String localeCode;
  final bool isCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        key: ValueKey('slot-card.${slot.id}'),
        onTap: () => _enter(context, ref),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    slot.avatar,
                    size: 88,
                    color: isCreated
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCreated
                        ? tr(localeCode, 'slot.continue')
                        : tr(localeCode, 'slot.new'),
                    key: ValueKey(
                      isCreated
                          ? 'slot-continue.${slot.id}'
                          : 'slot-new.${slot.id}',
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              if (isCreated)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    key: ValueKey('slot-reset.${slot.id}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _reset(context, ref),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enter(BuildContext context, WidgetRef ref) async {
    if (!isCreated) {
      await ref.read(saveSlotControllerProvider.notifier).createSlot(slot.id);
    }
    if (!context.mounted) return;
    ref.read(activeSlotProvider.notifier).select(slot.id);
    context.go('/');
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await ParentalGate.show(context);
    if (ok) {
      await ref.read(saveSlotControllerProvider.notifier).resetSlot(slot.id);
    }
  }
}
```

- [ ] **Step 4: router を `routerProvider` 化（/slots 起動 + redirect）**

Replace the entire contents of `lib/router.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/save_slots/slot_select_screen.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_screen.dart';
import 'package:kidsapp_treasurehunt/features/settings/settings_screen.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/slots',
    redirect: (context, state) {
      final hasSlot = ref.read(activeSlotProvider) != null;
      final atSlots = state.matchedLocation == '/slots';
      if (!hasSlot && !atSlots) return '/slots';
      return null;
    },
    routes: [
      GoRoute(
        path: '/slots',
        builder: (context, state) => const SlotSelectScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const TreasureMapScreen(),
      ),
      GoRoute(
        path: '/hunt/:sceneId',
        builder: (context, state) =>
            SeekFindScreen(sceneId: state.pathParameters['sceneId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 5: app.dart を `routerProvider` 参照に**

In `lib/app.dart`, replace the body of `build` so it watches the router provider:
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: tr(locale.languageCode, 'app.title'),
      theme: KidsTheme.light(),
      locale: locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
```
Remove the now-unused `import 'package:kidsapp_treasurehunt/router.dart';` only if it referenced the old `appRouter` symbol — keep the import (it now exposes `routerProvider`). Ensure no reference to the old `appRouter` remains.

- [ ] **Step 6: main.dart の起動時 ensureInitialUnlock を廃止**

Replace the entire contents of `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TreasureHuntApp(),
    ),
  );
}
```

- [ ] **Step 7: SaveSlotController の unit テストを追加**

Create `test/unit/save_slot_controller_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('createSlot marks created and unlocks first scene for that slot', () async {
    final c = await _container();
    await c.read(saveSlotControllerProvider.notifier).createSlot('slot1');

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isTrue);
    c.read(activeSlotProvider.notifier).select('slot1');
    expect(c.read(progressRepositoryProvider).isUnlocked('scene01'), isTrue);
  });

  test('slots have independent progress', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1');
    await ctrl.createSlot('slot2');

    c.read(activeSlotProvider.notifier).select('slot1');
    await c.read(progressRepositoryProvider).markCleared('scene01');

    c.read(activeSlotProvider.notifier).select('slot1');
    expect(c.read(progressRepositoryProvider).isCleared('scene01'), isTrue);
    c.read(activeSlotProvider.notifier).select('slot2');
    expect(c.read(progressRepositoryProvider).isCleared('scene01'), isFalse);
  });

  test('resetSlot clears progress and uncreates', () async {
    final c = await _container();
    final ctrl = c.read(saveSlotControllerProvider.notifier);
    await ctrl.createSlot('slot1');
    await ctrl.resetSlot('slot1');

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isFalse);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('progress.slot1.unlockedSceneIds'), isNull);
  });
}
```

- [ ] **Step 8: 既存 unit テストを slot 対応に更新**

Replace the entire contents of `test/unit/progress_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

Future<ProgressRepository> _repo(String slotId) async {
  final prefs = await SharedPreferences.getInstance();
  return ProgressRepository(prefs, slotId);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ensureInitialUnlock unlocks first scene only when empty', () async {
    final r = await _repo('slot1');
    await r.ensureInitialUnlock('scene01');
    expect(r.isUnlocked('scene01'), isTrue);
    expect(r.isUnlocked('scene02'), isFalse);
  });

  test('markCleared records scene as cleared', () async {
    final r = await _repo('slot1');
    expect(r.isCleared('scene01'), isFalse);
    await r.markCleared('scene01');
    expect(r.isCleared('scene01'), isTrue);
  });

  test('slots are independent', () async {
    final prefs = await SharedPreferences.getInstance();
    final s1 = ProgressRepository(prefs, 'slot1');
    final s2 = ProgressRepository(prefs, 'slot2');
    await s1.markCleared('scene01');
    expect(s1.isCleared('scene01'), isTrue);
    expect(s2.isCleared('scene01'), isFalse);
  });

  test('clearAll empties the slot', () async {
    final r = await _repo('slot1');
    await r.ensureInitialUnlock('scene01');
    await r.markCleared('scene01');
    await r.clearAll();
    expect(r.unlockedSceneIds(), isEmpty);
    expect(r.clearedSceneIds(), isEmpty);
  });
}
```

- [ ] **Step 9: 既存 widget テストを slot 対応に更新**

(a) Replace the entire contents of `test/widget/app_boot_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('boots to the slot select screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TreasureHuntApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('slot-card.slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });
}
```

(b) In `test/widget/treasure_map_screen_test.dart`, change the seed key and set an active slot before pumping. Replace the setup portion so it reads:
```dart
    SharedPreferences.setMockInitialValues({
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(activeSlotProvider.notifier).select('slot1');
```
(keep the rest — `UncontrolledProviderScope` pump and the `expect`s — unchanged). Ensure `activeSlotProvider` is imported via the existing `package:kidsapp_treasurehunt/providers.dart` import.

(c) In `test/widget/seek_find_screen_test.dart`, inside `_pumpScene`, after creating `container` and before `tester.pumpWidget(...)`, add:
```dart
  container.read(activeSlotProvider.notifier).select('slot1');
```
No seed change is needed (the scene loads from assets; `markCleared` writes to `progress.slot1.clearedSceneIds`, and the test asserts `progressRepositoryProvider.isCleared('scene01')` which now resolves to slot1).

- [ ] **Step 10: 解析と全テストを緑にする**

Run:
```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```
Expected: `No issues found!` と全テスト PASS。`progressRepositoryProvider` を使う箇所で `StateError` が出る場合は、該当テストで `activeSlotProvider.notifier.select('slot1')` を設定しているか確認する。

- [ ] **Step 11: コミット**

```bash
git add lib/data/progress_repository.dart lib/providers.dart \
  lib/features/save_slots/slot_select_screen.dart lib/router.dart lib/app.dart lib/main.dart \
  test/unit/save_slot_controller_test.dart test/unit/progress_repository_test.dart \
  test/widget/app_boot_test.dart test/widget/treasure_map_screen_test.dart \
  test/widget/seek_find_screen_test.dart
git commit -m "feat: slot-scoped progress + active slot + slot select screen"
```

---

## Task 4: SlotSelectScreen のフロー widget テスト

**Files:**
- Test: `test/widget/slot_select_screen_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/widget/slot_select_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  Map<String, Object> seed,
) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const TreasureHuntApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('tapping a new slot creates it and enters the map', (tester) async {
    final c = await _pumpApp(tester, {});

    await tester.tap(find.byKey(const ValueKey('slot-card.slot1')));
    await tester.pumpAndSettle();

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isTrue);
    expect(find.text('たからの ちず'), findsOneWidget); // 宝の地図ホーム
  });

  testWidgets('reset requires parental gate and uncreates the slot', (tester) async {
    final c = await _pumpApp(tester, {
      'save.createdSlotIds': ['slot1'],
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('slot-continue.slot1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('slot-reset.slot1')));
    await tester.pumpAndSettle(); // 保護者ゲートのダイアログ表示
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(c.read(saveSlotControllerProvider).contains('slot1'), isFalse);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });
}
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/widget/slot_select_screen_test.dart`
Expected: 実装前なら FAIL（または Task 3 完了済みなら緑になるはず — その場合はこのテストが追加カバレッジ）。落ちる場合は原因（ナビゲーション/ゲートのボタン文言 `OK`）を確認。

- [ ] **Step 3: 通過確認 + 全テスト**

Run:
```bash
fvm flutter test test/widget/slot_select_screen_test.dart
fvm flutter test
```
Expected: 当該 2 テスト PASS、全体 PASS。

- [ ] **Step 4: コミット**

```bash
fvm dart format test/widget/slot_select_screen_test.dart
git add test/widget/slot_select_screen_test.dart
git commit -m "test: slot select create/enter and reset-via-parental-gate flows"
```

---

## Task 5: 全体検証（Definition of Done）

**Files:** なし（検証のみ）

- [ ] **Step 1: フォーマット + 解析 + 全テスト**

```bash
bash scripts/check.sh
```
Expected: format 差分なし / `No issues found!` / 全テスト PASS。

- [ ] **Step 2: 実機/エミュレータで手動確認（DoD・任意）**

`fvm flutter run` で確認:
1. 起動するとスロット選択（3 アバター・すべて「あたらしく」）。
2. 1 つ選ぶと進捗初期化 → 宝の地図ホーム。クリアまで遊べる。
3. 一旦アプリ再起動 → 選択画面で当該スロットが「つづき」表示、選ぶと続きから。
4. 別スロットを新規で選ぶと独立した進捗で始まる（互いに影響しない）。
5. 作成済みスロットのゴミ箱 → 保護者ゲート → OK でリセット（「あたらしく」に戻る）。

- [ ] **Step 3: 整形差分があればコミット**

```bash
git add -A && git commit -m "style: apply dart format" || echo "nothing to format"
```

---

## Self-Review メモ（spec カバレッジ）

- spec §3.2 キー設計（`progress.<slotId>.*` / `save.createdSlotIds`）→ Task 1（SaveSlotRepository）/ Task 3 Step 1（ProgressRepository）。
- spec §3.3 Repository（slotId スコープ + clearAll）→ Task 3 Step 1。
- spec §4 状態（activeSlot / saveSlotController / progressRepositoryProvider 束縛）→ Task 3 Step 2、unit テスト Step 7。
- spec §5.1 ルーティング（/slots 初期 + redirect）→ Task 3 Step 4-5。§5.3 main → Step 6。
- spec §5.2 SlotSelectScreen（作成済み/未作成・リセット保護者ゲート）→ Task 3 Step 3 / Task 4。
- spec §6 リセット=保護者ゲート → `_SlotCard._reset`（Task 3 Step 3）+ Task 4 reset テスト。
- spec §7 テスト → Task 1/3/4 の各テスト。§8 DoD → Task 5。
- spec「言語は据え置き」→ `SettingsRepository`/`localeControllerProvider` 不変（変更なし）。
- 既存画面の無改修 → treasure_map / seek_find のロジックは変更せず、テストのみ activeSlot 設定を追加（Task 3 Step 9）。
```
