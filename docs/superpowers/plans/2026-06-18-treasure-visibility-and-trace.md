# 宝の可視化（A+B）＋なぞって発見 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** シーンに宝アイコンをはっきり描画し（B）、図鑑バーにお題アイコンを出し（A）、タップだけでなく指/ペンでなぞっても発見できるようにする（`InteractiveViewer` を撤去し画面フィット）。

**Architecture:** 共有の `targetIcon(id)` を図鑑とシーンの両方で使う。シーンは `LayoutBuilder` で実描画サイズを得て、宝を `normalizedRect × size` に `Positioned` 配置。`GestureDetector` の `onTapDown`/`onPanStart`/`onPanUpdate` を共通ハンドラに繋ぎ、最新の発見集合を `ref.read` で取得して `findHitTargetId` で判定。

**Tech Stack:** Flutter 3.44.2（fvm）/ Riverpod（手動）/ go_router。コマンドは `fvm flutter`。import は `package:kidsapp_treasurehunt/...`（`always_use_package_imports`）。

---

## 前提・注意

- 設計の正典: `docs/superpowers/specs/2026-06-18-treasure-visibility-and-trace-design.md`。
- スコープ外（混ぜない）: 完了画面の「ちずに もどる」ボタン・複数シーン・シーン別グラデ（spec #8）、実アート、ヒント、音声。
- 現状の `seek_find_screen.dart` は `InteractiveViewer` + 固定 `kSceneSize=Size(800,600)` + `onTapDown` のみ。完了処理は `ref.listen` 済み。これらを本プランで置換する。
- 各コミット後に対象テスト、最後に `bash scripts/check.sh`（fvm 経由）を緑にする。

## ファイル構成（触る範囲）

```
lib/features/seek_find/
  target_icons.dart                 # 新規: targetIcon(id)
  widgets/collection_bar.dart       # 変更: お題アイコン表示（A）
  seek_find_screen.dart             # 変更: B + なぞり + LayoutBuilder（kSceneSize 廃止）
test/
  unit/target_icons_test.dart       # 新規
  widget/collection_bar_test.dart   # 変更: 未発見アイコン assert 追加
  widget/seek_find_screen_test.dart # 変更: 実サイズ基準 + なぞりテスト
```

---

## Task 1: targetIcon（共有アイコンマップ）

**Files:**
- Create: `lib/features/seek_find/target_icons.dart`
- Test: `test/unit/target_icons_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/target_icons_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

void main() {
  test('returns mapped icon for known ids, fallback for unknown', () {
    expect(targetIcon('apple'), Icons.apple);
    expect(targetIcon('duck'), Icons.flutter_dash);
    expect(targetIcon('star'), Icons.star);
    expect(targetIcon('mystery'), Icons.help_outline);
  });
}
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/unit/target_icons_test.dart`
Expected: FAIL（`targetIcon` 未定義）。

- [ ] **Step 3: 実装**

Create `lib/features/seek_find/target_icons.dart`:
```dart
import 'package:flutter/material.dart';

/// 宝 id → 表示アイコン（プレースホルダ。実アートで差し替え）。
/// 図鑑バーとシーン描画の両方がこれを使い、見た目を一致させる。
const Map<String, IconData> _kTargetIcons = {
  'apple': Icons.apple,
  'duck': Icons.flutter_dash,
  'star': Icons.star,
};

IconData targetIcon(String id) => _kTargetIcons[id] ?? Icons.help_outline;
```

- [ ] **Step 4: 通過確認**

Run: `fvm flutter test test/unit/target_icons_test.dart`
Expected: PASS。

- [ ] **Step 5: コミット**

```bash
fvm dart format lib/features/seek_find/target_icons.dart test/unit/target_icons_test.dart
git add lib/features/seek_find/target_icons.dart test/unit/target_icons_test.dart
git commit -m "feat: add shared targetIcon map for seek-find"
```

---

## Task 2: 図鑑バーにお題アイコン（A）

**Files:**
- Modify: `lib/features/seek_find/widgets/collection_bar.dart`
- Test: `test/widget/collection_bar_test.dart`

- [ ] **Step 1: 失敗するテストを追記**

In `test/widget/collection_bar_test.dart`, add the import and a new test inside `main()`:
```dart
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
```
```dart
  testWidgets('shows target icons (grey when unfound, lit when found)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CollectionBar(targetIds: ['apple', 'duck'], foundIds: {'apple'}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('unfound.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);

    final duck = tester.widget<Icon>(find.byKey(const ValueKey('unfound.duck')));
    expect(duck.icon, targetIcon('duck'));
    final apple = tester.widget<Icon>(find.byKey(const ValueKey('found.apple')));
    expect(apple.icon, targetIcon('apple'));
  });
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/widget/collection_bar_test.dart`
Expected: FAIL（現状は found のとき汎用 `Icons.star`・`unfound.*` キー無し）。

- [ ] **Step 3: 実装（CollectionBar を置換）**

Replace the entire contents of `lib/features/seek_find/widgets/collection_bar.dart`:
```dart
import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

/// 画面下の図鑑。各 target に1枠、お題アイコンを表示し、見つけたら点灯する。
class CollectionBar extends StatelessWidget {
  const CollectionBar({
    super.key,
    required this.targetIds,
    required this.foundIds,
  });

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
                  color: foundIds.contains(id)
                      ? Colors.amber.shade200
                      : Colors.white,
                ),
                child: Icon(
                  targetIcon(id),
                  key: ValueKey(
                    foundIds.contains(id) ? 'found.$id' : 'unfound.$id',
                  ),
                  color: foundIds.contains(id)
                      ? Colors.amber.shade800
                      : Colors.grey.shade400,
                  size: 36,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 通過確認**

Run: `fvm flutter test test/widget/collection_bar_test.dart`
Expected: PASS（既存の "renders one slot per target and marks found ones" も維持。`found.apple` findsOneWidget / `found.duck` findsNothing は引き続き成立）。

- [ ] **Step 5: コミット**

```bash
fvm dart format lib/features/seek_find/widgets/collection_bar.dart test/widget/collection_bar_test.dart
git add lib/features/seek_find/widgets/collection_bar.dart test/widget/collection_bar_test.dart
git commit -m "feat: show target icons in collection bar (A)"
```

---

## Task 3: シーンに宝描画 + なぞって発見（B + 操作 + レイアウト）

`InteractiveViewer` と固定 `kSceneSize` を撤去し、`LayoutBuilder` で画面フィット。宝アイコンを
はっきり描画し、タップ/なぞりの両方で発見できるようにする。テストも実描画サイズ基準へ更新し、
なぞり発見のテストを追加する。

**Files:**
- Modify (replace): `lib/features/seek_find/seek_find_screen.dart`
- Modify (replace): `test/widget/seek_find_screen_test.dart`

- [ ] **Step 1: seek_find_screen.dart を置換**

Replace the entire contents of `lib/features/seek_find/seek_find_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

class SeekFindScreen extends ConsumerWidget {
  const SeekFindScreen({super.key, required this.sceneId});

  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneAsync = ref.watch(sceneProvider(sceneId));
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
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
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(scene.id));

    // 完了は副作用なので ref.listen で「全発見になった瞬間」に一度だけ発火させる。
    ref.listen(foundControllerProvider(scene.id), (previous, next) {
      final wasComplete = (previous?.length ?? 0) >= scene.targets.length;
      final nowComplete = next.length >= scene.targets.length;
      if (!wasComplete && nowComplete) {
        _handleComplete(scene.id);
      }
    });

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sceneSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _handleHit(d.localPosition, sceneSize),
                onPanStart: (d) => _handleHit(d.localPosition, sceneSize),
                onPanUpdate: (d) => _handleHit(d.localPosition, sceneSize),
                child: Stack(
                  key: const ValueKey('scene-content'),
                  fit: StackFit.expand,
                  children: [
                    // プレースホルダ背景（実アートは後で差し替え）
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
                        ),
                      ),
                    ),
                    // 宝アイコンをはっきり描画。発見済みは点灯 + キラッ。
                    for (final t in scene.targets)
                      Positioned(
                        left: t.normalizedRect.left * sceneSize.width,
                        top: t.normalizedRect.top * sceneSize.height,
                        width: t.normalizedRect.width * sceneSize.width,
                        height: t.normalizedRect.height * sceneSize.height,
                        child: _TargetView(
                          icon: targetIcon(t.id),
                          found: found.contains(t.id),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        CollectionBar(
          targetIds: [for (final t in scene.targets) t.id],
          foundIds: found,
        ),
        if (_completed)
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

  Future<void> _handleComplete(String sceneId) async {
    await ref.read(progressRepositoryProvider).markCleared(sceneId);
    await ref.read(audioServiceProvider).playComplete();
    if (mounted) setState(() => _completed = true);
  }

  /// タップ/なぞり共通。最新の発見集合を読み、未発見の宝に当たれば発見にする。
  void _handleHit(Offset localPosition, Size sceneSize) {
    final scene = widget.scene;
    final found = ref.read(foundControllerProvider(scene.id));
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: sceneSize,
      targets: scene.targets,
      foundIds: found,
    );
    if (hitId == null) return; // 空振りは罰しない
    ref.read(foundControllerProvider(scene.id).notifier).markFound(hitId);
    ref.read(audioServiceProvider).playFound();
  }
}

class _TargetView extends StatelessWidget {
  const _TargetView({required this.icon, required this.found});

  final IconData icon;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            icon,
            color: found ? Colors.amber.shade700 : Colors.brown.shade600,
          ),
        ),
        if (found) const FoundBurst(),
      ],
    );
  }
}
```

- [ ] **Step 2: seek_find_screen_test.dart を置換**

Replace the entire contents of `test/widget/seek_find_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/audio/audio_service.dart';

// scene01.json の target 正規化中心 (left+width/2, top+height/2)。
const _sceneCenters = {
  'apple': Offset(0.10 + 0.07, 0.15 + 0.09), // (0.17, 0.24)
  'duck': Offset(0.60 + 0.07, 0.30 + 0.09), // (0.67, 0.39)
  'star': Offset(0.40 + 0.07, 0.68 + 0.09), // (0.47, 0.77)
};

Future<ProviderContainer> _pumpScene(WidgetTester tester) async {
  // シーンが AppBar/図鑑の下に十分な大きさで収まるよう、テスト面を広げる。
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioServiceProvider.overrideWithValue(SilentAudioService()),
    ],
  );
  addTearDown(container.dispose);
  container.read(activeSlotProvider.notifier).select('slot1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SeekFindScreen(sceneId: 'scene01')),
    ),
  );
  // rootBundle のシーン読み込みを実イベントループで先に解決させる。
  await tester.runAsync(() => container.read(sceneProvider('scene01').future));
  await tester.pumpAndSettle();
  return container;
}

/// scene-content の実描画サイズ・原点を基準に、対象中心のグローバル座標を返す。
Offset _targetGlobal(WidgetTester tester, String id) {
  final origin = tester.getTopLeft(find.byKey(const ValueKey('scene-content')));
  final size = tester.getSize(find.byKey(const ValueKey('scene-content')));
  final c = _sceneCenters[id]!;
  return origin + Offset(c.dx * size.width, c.dy * size.height);
}

Future<void> _tapTarget(WidgetTester tester, String id) async {
  await tester.tapAt(_targetGlobal(tester, id));
  await tester.pump();
}

void main() {
  testWidgets('tapping a target fills its collection slot', (tester) async {
    await _pumpScene(tester);

    expect(find.byKey(const ValueKey('found.apple')), findsNothing);
    await _tapTarget(tester, 'apple');
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
  });

  testWidgets('tracing (drag) over a target finds it', (tester) async {
    await _pumpScene(tester);

    final center = _targetGlobal(tester, 'duck');
    // duck の上を短くなぞる（touchSlop を超える移動でパンとして認識される）。
    final gesture = await tester.startGesture(center - const Offset(24, 0));
    await gesture.moveTo(center);
    await gesture.moveTo(center + const Offset(24, 0));
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const ValueKey('found.duck')), findsOneWidget);
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

  testWidgets('found-state resets on re-entry (auto-dispose, no leak)', (
    tester,
  ) async {
    final container = await _pumpScene(tester);
    container.read(foundControllerProvider('scene01').notifier).markFound('apple');
    expect(container.read(foundControllerProvider('scene01')), {'apple'});
  });
}
```

> 注意: `_sceneCenters` は scene01.json の座標から計算した**正規化中心**。`duck` のなぞり開始点
> `center - Offset(24,0)` は duck 矩形（横 0.60〜0.74 ≒ 600〜740px @幅1000）内に収まる。

- [ ] **Step 3: 解析と対象テスト**

Run:
```bash
fvm dart format .
fvm flutter analyze
fvm flutter test test/widget/seek_find_screen_test.dart
```
Expected: `No issues found!` と当該ファイルの 4 テスト PASS。
- もし `scene-content` の getSize が 0 になりレイアウト/タップが失敗する場合、`Stack` に
  `fit: StackFit.expand` が付いているか確認（全 Positioned 子のみだと既定の loose では潰れる）。
- なぞりテストが落ちる場合、`onPanStart`/`onPanUpdate` が `_handleHit` に繋がっているか、
  開始点が duck 矩形内かを確認。設計は変えない。

- [ ] **Step 4: 全テスト**

Run: `fvm flutter test`
Expected: 全 PASS（総数を報告）。

- [ ] **Step 5: コミット**

```bash
git add lib/features/seek_find/seek_find_screen.dart test/widget/seek_find_screen_test.dart
git commit -m "feat: draw treasures + tap/trace to find, fit scene to screen"
```

---

## Task 4: 全体検証（Definition of Done）

**Files:** なし（検証のみ）

- [ ] **Step 1: format + analyze + 全テスト**

```bash
bash scripts/check.sh
```
Expected: format 差分なし / `No issues found!` / 全テスト PASS。

- [ ] **Step 2: 実機/エミュレータで手動確認（任意）**

`fvm flutter run` でスロット選択 → scene01 に入り:
1. 背景（グラデ）に宝アイコン（りんご/とり/ほし）が**見える**。
2. 宝を**タップ**で点灯＋図鑑充填。
3. 宝の上を**指/ペンでなぞる**と発見（1ストロークで複数可）。
4. 図鑑は最初お題アイコン（グレー）→ 見つけて点灯。
5. 空振りは無反応。3個発見で「みつけたね！」。

- [ ] **Step 3: 整形差分があればコミット**

```bash
git add -A && git commit -m "style: apply dart format" || echo "nothing to format"
```

---

## Self-Review メモ（spec カバレッジ）

- spec §3.1 `targetIcon` 共有 → Task 1。
- spec §3.2 図鑑 A（未発見グレー/発見点灯・お題アイコン） → Task 2。
- spec §3.3 シーン B（はっきり描画）+ なぞり（onTapDown/onPanStart/onPanUpdate, 最新 found を ref.read）+ レイアウト（InteractiveViewer 撤去・LayoutBuilder・kSceneSize 廃止・実サイズで判定） → Task 3。
- spec §3.4 `findHitTargetId` 不変・実描画サイズを渡す → Task 3（呼び出し側のみ変更）。
- spec §5 テスト（targetIcon / CollectionBar / 実サイズ基準タップ / なぞり / コンプリート） → Task 1/2/3。
- spec §6 影響（kSceneSize 廃止・既存テスト更新・CollectionBar API 不変・発見→図鑑→完了→slot 永続化 不変） → Task 3。
- スコープ外（完了ボタン/複数シーン/シーン別グラデ #8・実アート・ヒント・音声） → 触れない。
```
