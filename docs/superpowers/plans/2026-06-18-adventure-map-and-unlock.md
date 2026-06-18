# アドベンチャーマップ + 順次アンロック Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** クリアで次シーンが解放される順次アンロックを実装し、ホームを蛇行パス＋状態ノードのアドベンチャーマップに刷新する。

**Architecture:** 進行は `completeScene(progress, sceneId)`（純関数: markCleared + unlock(nextSceneId)）に集約し unit で担保。ホームは `LayoutBuilder` + `CustomPaint`（点線パス）+ `Positioned` ノード（クリア/「いま!」脈動/ロック）。すべて純 Flutter・プレースホルダ（実アート後差し替え）。

**Tech Stack:** Flutter 3.44.2（fvm）/ Riverpod（手動）/ go_router。コマンドは `fvm flutter`。import は `package:kidsapp_treasurehunt/...`（`always_use_package_imports`）。

---

## 前提・注意

- 設計の正典: `docs/superpowers/specs/2026-06-18-adventure-map-and-unlock-design.md`（#8 を取り込み）。
- **脈動は repeating アニメ**。ホームの widget テストは **`pump()` のみ**（`pumpAndSettle()` を呼ぶとハングする）。
- `seek_find_screen` の widget テストは引き続き skip（既存方針）。完了→次解放は `completeScene` の unit で担保。
- 各コミット後に対象テスト、最後に `bash scripts/check.sh` を緑にする。

## ファイル構成（触る範囲）

```
lib/scenes_catalog.dart                         # 変更: mapPos/themeIcon + nextSceneId + completeScene
lib/features/seek_find/target_icons.dart        # 変更: ball/flower/heart 追加
lib/shared/strings/strings.dart                 # 変更: target.* + seek.toMap 追加
assets/scenes/scene02.json, scene03.json        # 新規
lib/features/seek_find/seek_find_screen.dart    # 変更: completeScene / シーン別グラデ / 「ちずにもどる」
lib/features/treasure_map/treasure_map_screen.dart  # 全面刷新: アドベンチャーマップ
test/unit/scenes_catalog_test.dart              # 新規
test/unit/scene_def_test.dart                   # 追記: 全シーン asset ロード
test/unit/target_icons_test.dart, strings_test.dart # 追記
test/widget/treasure_map_screen_test.dart       # 置換: ノード/状態/ヘッダー
```

---

## Task 1: カタログ拡張 + nextSceneId + completeScene

**Files:**
- Modify (replace): `lib/scenes_catalog.dart`
- Test: `test/unit/scenes_catalog_test.dart`

- [ ] **Step 1: 失敗するテストを書く**

Create `test/unit/scenes_catalog_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nextSceneId follows catalog order; null at end/unknown', () {
    expect(nextSceneId('scene01'), 'scene02');
    expect(nextSceneId('scene02'), 'scene03');
    expect(nextSceneId('scene03'), isNull);
    expect(nextSceneId('mystery'), isNull);
  });

  test('completeScene marks cleared and unlocks the next scene', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene01');
    expect(progress.isCleared('scene01'), isTrue);
    expect(progress.isUnlocked('scene02'), isTrue);
  });

  test('completeScene on the last scene does not throw / unlock', () async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressRepository(prefs, 'slot1');
    await completeScene(progress, 'scene03');
    expect(progress.isCleared('scene03'), isTrue);
    expect(progress.isUnlocked('scene03'), isFalse);
  });
}
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/unit/scenes_catalog_test.dart`
Expected: FAIL（`nextSceneId`/`completeScene`/`mapPos` 未定義 or 旧 catalog）。

- [ ] **Step 3: カタログを置換**

Replace the entire contents of `lib/scenes_catalog.dart`:
```dart
import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';

/// ホームの宝の地図に並べるシーン。MVP は scene01 のみ最初から解放。
class SceneCatalogEntry {
  const SceneCatalogEntry(this.id, this.titleKey, this.mapPos, this.themeIcon);

  final String id;
  final String titleKey;
  final Offset mapPos; // 0.0–1.0 正規化（マップ上の位置）
  final IconData themeIcon; // 森 / 海 / 空

  bool get hasScene => id == 'scene01' || id == 'scene02' || id == 'scene03';
}

const String kFirstSceneId = 'scene01';

const List<SceneCatalogEntry> kSceneCatalog = [
  SceneCatalogEntry('scene01', 'scene.scene01.title', Offset(0.20, 0.32), Icons.park),
  SceneCatalogEntry('scene02', 'scene.scene02.title', Offset(0.52, 0.60), Icons.water),
  SceneCatalogEntry('scene03', 'scene.scene03.title', Offset(0.82, 0.30), Icons.cloud),
];

/// kSceneCatalog の並び順で次のシーン id。最後 / 未知なら null。
String? nextSceneId(String id) {
  final index = kSceneCatalog.indexWhere((e) => e.id == id);
  if (index < 0 || index + 1 >= kSceneCatalog.length) return null;
  return kSceneCatalog[index + 1].id;
}

/// シーンクリア時の進行処理: クリア記録 + 次シーン解放（最後なら no-op）。
Future<void> completeScene(ProgressRepository progress, String sceneId) async {
  await progress.markCleared(sceneId);
  final next = nextSceneId(sceneId);
  if (next != null) {
    await progress.unlock(next);
  }
}
```
> `Offset`/`IconData`/`Icons` は `package:flutter/material.dart` から得る（`dart:ui` 不要）。
> `hasScene` は将来の安全弁（現状 3 つとも true）。

- [ ] **Step 4: 通過確認 + 全体**

Run: `fvm flutter test test/unit/scenes_catalog_test.dart` → PASS（3）。
Run: `fvm flutter analyze` → "No issues found!"。
Run: `fvm flutter test` → 既存も含め全 PASS（旧 treasure_map は `entry.id`/`titleKey` のみ使用のため無影響）。

- [ ] **Step 5: コミット**

```bash
fvm dart format lib/scenes_catalog.dart test/unit/scenes_catalog_test.dart
git add lib/scenes_catalog.dart test/unit/scenes_catalog_test.dart
git commit -m "feat: catalog mapPos/themeIcon + nextSceneId + completeScene"
```

---

## Task 2: お題アイコン / 文字列の追加

**Files:**
- Modify: `lib/features/seek_find/target_icons.dart`
- Modify: `lib/shared/strings/strings.dart`
- Test: `test/unit/target_icons_test.dart`, `test/unit/strings_test.dart`

- [ ] **Step 1: 失敗するテストを追記**

In `test/unit/target_icons_test.dart` add inside `main()`:
```dart
  test('returns icons for scene02/03 targets', () {
    expect(targetIcon('ball'), Icons.sports_soccer);
    expect(targetIcon('flower'), Icons.local_florist);
    expect(targetIcon('heart'), Icons.favorite);
  });
```
In `test/unit/strings_test.dart` add inside `main()`:
```dart
  test('resolves new target + toMap strings', () {
    expect(tr('ja', 'target.ball'), 'ボール');
    expect(tr('en', 'target.flower'), 'Flower');
    expect(tr('ja', 'seek.toMap'), 'ちずに もどる');
  });
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/unit/target_icons_test.dart test/unit/strings_test.dart`
Expected: FAIL（未定義キーは key 文字列 / `Icons.help_outline` を返す）。

- [ ] **Step 3: 実装**

In `lib/features/seek_find/target_icons.dart`, add these entries to `_kTargetIcons`:
```dart
  'ball': Icons.sports_soccer,
  'flower': Icons.local_florist,
  'heart': Icons.favorite,
```
In `lib/shared/strings/strings.dart`, add to the `'ja'` map:
```dart
    'target.ball': 'ボール',
    'target.flower': 'おはな',
    'target.heart': 'ハート',
    'seek.toMap': 'ちずに もどる',
```
and to the `'en'` map:
```dart
    'target.ball': 'Ball',
    'target.flower': 'Flower',
    'target.heart': 'Heart',
    'seek.toMap': 'Back to map',
```

- [ ] **Step 4: 通過確認**

Run: `fvm flutter test test/unit/target_icons_test.dart test/unit/strings_test.dart` → PASS。

- [ ] **Step 5: コミット**

```bash
fvm dart format lib/features/seek_find/target_icons.dart lib/shared/strings/strings.dart test/unit/target_icons_test.dart test/unit/strings_test.dart
git add lib/features/seek_find/target_icons.dart lib/shared/strings/strings.dart test/unit/target_icons_test.dart test/unit/strings_test.dart
git commit -m "feat: add ball/flower/heart icons + labels + seek.toMap string"
```

---

## Task 3: scene02 / scene03 データ

**Files:**
- Create: `assets/scenes/scene02.json`, `assets/scenes/scene03.json`
- Test: `test/unit/scene_def_test.dart`（追記）

- [ ] **Step 1: 失敗するテストを追記**

In `test/unit/scene_def_test.dart`, ensure binding is initialized and add an asset-load test. Add at the very top of `main()`:
```dart
  TestWidgetsFlutterBinding.ensureInitialized();
```
and add this test inside `main()`:
```dart
  test('loads scene02 (4 targets) and scene03 (5 targets) from assets', () async {
    final s2 = await SceneDef.loadAsset('scene02');
    expect(s2.targets, hasLength(4));
    final s3 = await SceneDef.loadAsset('scene03');
    expect(s3.targets, hasLength(5));
  });
```

- [ ] **Step 2: 失敗確認**

Run: `fvm flutter test test/unit/scene_def_test.dart`
Expected: FAIL（scene02/03 asset 不在で `loadString` が例外）。

- [ ] **Step 3: データを作成**

Create `assets/scenes/scene02.json`:
```json
{
  "id": "scene02",
  "titleKey": "scene.scene02.title",
  "imageAsset": "assets/scenes/scene02.png",
  "targets": [
    { "id": "apple",  "labelKey": "target.apple",  "left": 0.12, "top": 0.18, "width": 0.14, "height": 0.18 },
    { "id": "ball",   "labelKey": "target.ball",   "left": 0.62, "top": 0.22, "width": 0.14, "height": 0.18 },
    { "id": "star",   "labelKey": "target.star",   "left": 0.28, "top": 0.62, "width": 0.14, "height": 0.18 },
    { "id": "flower", "labelKey": "target.flower", "left": 0.70, "top": 0.64, "width": 0.14, "height": 0.18 }
  ]
}
```
Create `assets/scenes/scene03.json`:
```json
{
  "id": "scene03",
  "titleKey": "scene.scene03.title",
  "imageAsset": "assets/scenes/scene03.png",
  "targets": [
    { "id": "apple",  "labelKey": "target.apple",  "left": 0.10, "top": 0.16, "width": 0.13, "height": 0.16 },
    { "id": "duck",   "labelKey": "target.duck",   "left": 0.40, "top": 0.20, "width": 0.13, "height": 0.16 },
    { "id": "star",   "labelKey": "target.star",   "left": 0.72, "top": 0.18, "width": 0.13, "height": 0.16 },
    { "id": "flower", "labelKey": "target.flower", "left": 0.24, "top": 0.64, "width": 0.13, "height": 0.16 },
    { "id": "heart",  "labelKey": "target.heart",  "left": 0.62, "top": 0.62, "width": 0.13, "height": 0.16 }
  ]
}
```
> `assets/scenes/` は pubspec で宣言済みのため新 json は自動でバンドルされる（pubspec 変更不要）。

- [ ] **Step 4: 通過確認**

Run: `fvm flutter test test/unit/scene_def_test.dart` → PASS。

- [ ] **Step 5: コミット**

```bash
git add assets/scenes/scene02.json assets/scenes/scene03.json test/unit/scene_def_test.dart
git commit -m "feat: add scene02 (4) and scene03 (5) data"
```

---

## Task 4: シーン画面 — 順次アンロック / シーン別グラデ / 「ちずにもどる」

**Files:**
- Modify (replace): `lib/features/seek_find/seek_find_screen.dart`

（`seek_find_screen` の widget テストは skip 済みのため、本タスクは analyze + 全体 test が緑であることで確認する。完了→次解放は Task 1 の `completeScene` unit で担保。）

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
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

const Map<String, List<Color>> _sceneGradients = {
  'scene01': [Color(0xFFB2DFDB), Color(0xFFC8E6C9)],
  'scene02': [Color(0xFFBBDEFB), Color(0xFFB3E5FC)],
  'scene03': [Color(0xFFE1F5FE), Color(0xFFD1C4E9)],
};

List<Color> _gradientFor(String sceneId) =>
    _sceneGradients[sceneId] ?? const [Color(0xFFB2DFDB), Color(0xFFC8E6C9)];

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
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _gradientFor(scene.id),
                        ),
                      ),
                    ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(localeCode, 'seek.complete'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                KidsButton(
                  label: tr(localeCode, 'seek.toMap'),
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleComplete(String sceneId) async {
    await completeScene(ref.read(progressRepositoryProvider), sceneId);
    await ref.read(audioServiceProvider).playComplete();
    if (mounted) setState(() => _completed = true);
  }

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

- [ ] **Step 2: 解析 + 全テスト**

Run:
```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```
Expected: `No issues found!`、全 PASS（`seek_find_screen` テストは skip のまま）。

- [ ] **Step 3: コミット**

```bash
git add lib/features/seek_find/seek_find_screen.dart
git commit -m "feat: unlock next on complete + per-scene gradient + back-to-map button"
```

---

## Task 5: アドベンチャーマップ（ホーム刷新）

**Files:**
- Modify (replace): `lib/features/treasure_map/treasure_map_screen.dart`
- Modify (replace): `test/widget/treasure_map_screen_test.dart`

- [ ] **Step 1: treasure_map_screen.dart を置換**

Replace the entire contents of `lib/features/treasure_map/treasure_map_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

class TreasureMapScreen extends ConsumerWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final clearedCount =
        kSceneCatalog.where((e) => progress.isCleared(e.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(localeCode, 'home.title')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${tr(localeCode, 'home.cleared')} '
                '$clearedCount/${kSceneCatalog.length} 🏆',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                ),
              ),
              CustomPaint(
                size: size,
                painter: _TrailPainter(progress: progress),
              ),
              for (final entry in kSceneCatalog)
                Positioned(
                  left: entry.mapPos.dx * size.width - 56,
                  top: entry.mapPos.dy * size.height - 56,
                  width: 112,
                  height: 112,
                  child: _MapNode(
                    entry: entry,
                    localeCode: localeCode,
                    unlocked: progress.isUnlocked(entry.id),
                    cleared: progress.isCleared(entry.id),
                    onTap: progress.isUnlocked(entry.id)
                        ? () => context.go('/hunt/${entry.id}')
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.progress});

  final ProgressRepository progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < kSceneCatalog.length - 1; i++) {
      final a = kSceneCatalog[i];
      final b = kSceneCatalog[i + 1];
      final p1 = Offset(a.mapPos.dx * size.width, a.mapPos.dy * size.height);
      final p2 = Offset(b.mapPos.dx * size.width, b.mapPos.dy * size.height);
      final done = progress.isCleared(a.id);
      final paint = Paint()
        ..color = done ? Colors.brown.shade600 : Colors.brown.shade200
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      _drawDashed(canvas, p1, p2, paint);
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 14.0;
    const gap = 10.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var travelled = 0.0;
    while (travelled < total) {
      final end = travelled + dash < total ? travelled + dash : total;
      canvas.drawLine(a + dir * travelled, a + dir * end, paint);
      travelled += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) => true;
}

class _MapNode extends StatefulWidget {
  const _MapNode({
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
  State<_MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<_MapNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _isCurrent => widget.unlocked && !widget.cleared;

  @override
  void initState() {
    super.initState();
    if (_isCurrent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MapNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_isCurrent && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateKey = widget.cleared
        ? 'node-cleared.${widget.entry.id}'
        : widget.unlocked
        ? 'node-current.${widget.entry.id}'
        : 'node-locked.${widget.entry.id}';
    final color = widget.cleared
        ? Colors.amber.shade600
        : widget.unlocked
        ? Colors.orange.shade400
        : Colors.grey.shade400;

    Widget medallion = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(
        widget.entry.themeIcon,
        key: ValueKey(stateKey),
        color: color,
        size: 40,
      ),
    );

    if (_isCurrent) {
      medallion = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.12).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: medallion,
      );
    }

    return GestureDetector(
      key: ValueKey('scene-node.${widget.entry.id}'),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                medallion,
                if (!widget.unlocked)
                  const Icon(Icons.lock, color: Colors.brown, size: 26),
                if (widget.cleared)
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(widget.localeCode, widget.entry.titleKey),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: treasure_map_screen_test.dart を置換**

Replace the entire contents of `test/widget/treasure_map_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<void> _pumpHome(WidgetTester tester, Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container.read(activeSlotProvider.notifier).select('slot1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TreasureMapScreen()),
    ),
  );
  // 「いま!」ノードは repeating アニメ。pumpAndSettle は使わない。
  await tester.pump();
}

void main() {
  testWidgets('fresh slot: scene01 current, others locked', (tester) async {
    await _pumpHome(tester, {
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('scene-node.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-node.scene03')), findsOneWidget);

    expect(find.byKey(const ValueKey('node-current.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene03')), findsOneWidget);

    expect(find.textContaining('0/3'), findsOneWidget);
  });

  testWidgets('cleared scene01 + unlocked scene02 reflects states', (
    tester,
  ) async {
    await _pumpHome(tester, {
      'progress.slot1.unlockedSceneIds': ['scene01', 'scene02'],
      'progress.slot1.clearedSceneIds': ['scene01'],
    });

    expect(find.byKey(const ValueKey('node-cleared.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-current.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('node-locked.scene03')), findsOneWidget);

    expect(find.textContaining('1/3'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 解析 + テスト**

Run:
```bash
fvm dart format .
fvm flutter analyze
fvm flutter test test/widget/treasure_map_screen_test.dart
fvm flutter test
```
Expected: `No issues found!`、treasure_map の 2 テスト PASS、全体 PASS。
- もし teardown で "A Ticker was active" 等が出たら、`pumpAndSettle()` を呼んでいないか確認（脈動は repeating のため使わない。`pump()` のみ）。

- [ ] **Step 4: コミット**

```bash
git add lib/features/treasure_map/treasure_map_screen.dart test/widget/treasure_map_screen_test.dart
git commit -m "feat: adventure-map home (trail + node states + pulse + progress)"
```

---

## Task 6: 全体検証（Definition of Done）

**Files:** なし（検証のみ）

- [ ] **Step 1: format + analyze + 全テスト**

```bash
bash scripts/check.sh
```
Expected: format 差分なし / `No issues found!` / 全テスト PASS（`seek_find_screen` は skip のまま、その他緑）。

- [ ] **Step 2: 実機/エミュレータ手動確認（任意）**

`fvm flutter run` で:
1. ホームが地図（背景 + 蛇行パス + 3ノード）。scene01 が「いま!」脈動、他はロック。
2. scene01 をクリア（宝を全部発見 → 「みつけたね！」→「ちずに もどる」）→ ホームで **scene02 が解放**（パス色付き・scene02 脈動）。進捗「クリア 1/3」。
3. scene02 → scene03 も同様。scene03 クリアで「クリア 3/3」。
4. 各シーンの背景色が異なる。
5. 別スロットは独立した進行。

- [ ] **Step 3: 整形差分があればコミット**

```bash
git add -A && git commit -m "style: apply dart format" || echo "nothing to format"
```

---

## Self-Review メモ（spec カバレッジ）

- spec §3.1 カタログ拡張 / §3.2 completeScene → Task 1。§3.3 アイコン/文字列 → Task 2、データ → Task 3。§3.4 シーン画面（completeScene/グラデ/「ちずにもどる」） → Task 4。
- spec §4 アドベンチャーマップ（パス/ノード状態/脈動/進捗ヘッダー/テーマアイコン/タップ遷移） → Task 5。
- spec §5 テスト（completeScene unit / 全シーン asset / home は pump() のみ / seek_find skip 継続） → Task 1/3/5。
- spec §6 DoD → Task 6。
- 既存への影響: Task 1 はカタログ追加で旧 treasure_map に無影響（Task 5 で刷新）。pumpAndSettle 不使用を Task 5 で明記。
```
