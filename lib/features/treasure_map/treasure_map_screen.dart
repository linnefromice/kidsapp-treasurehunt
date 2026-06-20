import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/progress_repository.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/treasure_map_canvas.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 選択中モードでの「現在地」= まだクリアしていない最初の解放済みシーンの index。
/// 全クリア / 先頭未解放なら null（マーチング足跡を出さない）。
int? _currentNodeIndex(ProgressRepository progress, GameMode mode) {
  for (var i = 0; i < kSceneCatalog.length; i++) {
    final e = kSceneCatalog[i];
    if (progress.isUnlocked(mode, e.id) && !progress.isCleared(mode, e.id)) {
      return i;
    }
  }
  return null;
}

class TreasureMapScreen extends ConsumerStatefulWidget {
  const TreasureMapScreen({super.key});

  @override
  ConsumerState<TreasureMapScreen> createState() => _TreasureMapScreenState();
}

class _TreasureMapScreenState extends ConsumerState<TreasureMapScreen> {
  GameMode _mode = GameMode.easy;

  @override
  void initState() {
    super.initState();
    // 既存スロット救済: 各モードの初期解放（scene01）が無ければ遅延シードする。
    // スロット生成時に 3 モード分シード済みのため、通常は冪等で no-op。
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSeeded());
  }

  Future<void> _ensureSeeded() async {
    // アクティブスロット未選択なら progressRepositoryProvider は throw する。
    // この postFrameCallback は unawaited のため、ここで握って no-op にする
    // （ルート遷移の境界でスロットが外れた瞬間などを防御）。
    if (!mounted || ref.read(activeSlotProvider) == null) return;
    final progress = ref.read(progressRepositoryProvider);
    var seeded = false;
    for (final mode in GameMode.values) {
      if (progress.unlockedSceneIds(mode).isEmpty) {
        await progress.ensureInitialUnlock(mode, kFirstSceneId);
        seeded = true;
      }
    }
    if (seeded && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final trail = ref.watch(trailSettingControllerProvider);
    final activeSlotId = ref.watch(activeSlotProvider);
    final avatarEmoji = ref.watch(
      saveSlotControllerProvider.select(
        (slots) => (activeSlotId != null && activeSlotId != kFreeModeSlotId)
            ? slots[activeSlotId]
            : null,
      ),
    );

    final isHard = _mode == GameMode.hard;
    // バッジ・カウンタ・軌跡・現在地はすべて選択中モードの進捗を反映する。
    final clearedForMode = kSceneCatalog
        .where((e) => progress.isCleared(_mode, e.id))
        .map((e) => e.id)
        .toSet();
    final currentIndex = _currentNodeIndex(progress, _mode);

    return Scaffold(
      appBar: AppBar(
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
        title: Text(tr(localeCode, 'home.title')),
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
          _TrailBadge(setting: trail, onTap: () => context.go('/settings')),
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
              // 1. 羊皮紙背景（静的・隔離）
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: const ParchmentPainter(),
                ),
              ),
              // 2. 曲線ルート + クリア済み区間の足跡（選択中モードのクリアを反映）
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: TrailPainter(clearedIds: clearedForMode),
                ),
              ),
              // 3. 現在地へ向かう足跡（アニメ・隔離）。現在地が無ければ描かない。
              if (currentIndex != null && currentIndex > 0)
                RepaintBoundary(
                  child: _CurrentLegFootprints(
                    size: size,
                    endIndex: currentIndex,
                  ),
                ),
              // 4. ノード群
              for (final entry in kSceneCatalog)
                Positioned(
                  left: entry.mapPos.dx * size.width - 56,
                  top: entry.mapPos.dy * size.height - 56,
                  width: 112,
                  height: 112,
                  child: _MapNode(
                    entry: entry,
                    localeCode: localeCode,
                    unlocked: progress.isUnlocked(_mode, entry.id),
                    cleared: clearedForMode.contains(entry.id),
                    onTap: progress.isUnlocked(_mode, entry.id)
                        ? () =>
                              context.go('/hunt/${entry.id}?mode=${_mode.name}')
                        : null,
                  ),
                ),
              // 5. モード切替トグル（Easy / Normal / Hard を常時表示）
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: _ModeToggle(
                    mode: _mode,
                    localeCode: localeCode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 「やさしい / ふつう / むずかしい」を切り替えるピル型トグル。常時表示。
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.localeCode,
    required this.onChanged,
  });

  final GameMode mode;
  final String localeCode;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('map-mode-toggle'),
      color: const Color(0xFFEDE3D2),
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeChip(
              keyValue: 'mode-easy',
              label: tr(localeCode, 'home.modeEasy'),
              selected: mode == GameMode.easy,
              onTap: () => onChanged(GameMode.easy),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              keyValue: 'mode-normal',
              label: tr(localeCode, 'home.modeNormal'),
              selected: mode == GameMode.normal,
              onTap: () => onChanged(GameMode.normal),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              keyValue: 'mode-hard',
              label: '🔥 ${tr(localeCode, 'home.modeHard')}',
              selected: mode == GameMode.hard,
              onTap: () => onChanged(GameMode.hard),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.keyValue,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String keyValue;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: ValueKey(keyValue),
        onTap: onTap,
        child: Container(
          // タッチターゲット 60dp 以上を確保（子供向け UX 基準）。
          constraints: const BoxConstraints(minWidth: 96, minHeight: 60),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.amber.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.brown.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

/// 現在地へ向かう 1 区間だけに、足跡が順番にフェードインする「マーチング」演出。
/// 低振幅・緩ループで、進む方向をそっと誘目する（急かさない）。
class _CurrentLegFootprints extends StatefulWidget {
  const _CurrentLegFootprints({required this.size, required this.endIndex});

  final Size size;
  final int endIndex;

  @override
  State<_CurrentLegFootprints> createState() => _CurrentLegFootprintsState();
}

class _CurrentLegFootprintsState extends State<_CurrentLegFootprints>
    with SingleTickerProviderStateMixin {
  late final AnimationController _march;

  @override
  void initState() {
    super.initState();
    _march = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _march.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _march,
      builder: (context, _) => CustomPaint(
        size: widget.size,
        painter: _LegFootstepsPainter(
          t: _march.value,
          endIndex: widget.endIndex,
        ),
      ),
    );
  }
}

/// `endIndex` 区間に等間隔の足跡を置き、`t`（0..1 ループ）に応じて先頭から順に
/// 明滅させる。先頭位置は環状に巻き戻るので連続的な行進に見える。
class _LegFootstepsPainter extends CustomPainter {
  _LegFootstepsPainter({required this.t, required this.endIndex});

  final double t;
  final int endIndex;

  static const int _count = 8;
  static const Color _color = Color(0xFFFF8F00);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = trailNodeCenters(size);
    final path = legPath(pts, endIndex);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final head = t * _count;
    var side = 1.0;
    for (var i = 0; i < _count; i++) {
      final dist = ((i + 0.5) / _count) * metric.length;
      final tan = metric.getTangentForOffset(dist);
      if (tan == null) {
        side = -side;
        continue;
      }
      // 行進する「光の頭」が i を通過する時に最も明るく。環状の最短距離で評価。
      final raw = head - i;
      final wrapped = math.min(
        raw.abs(),
        math.min((raw - _count).abs(), (raw + _count).abs()),
      );
      final wave = math.exp(-(wrapped * wrapped) / 1.2);
      final alpha = (0.18 + 0.55 * wave).clamp(0.0, 0.85);

      final normal = Offset(-tan.vector.dy, tan.vector.dx);
      paintFootprint(
        canvas,
        tan.position + normal * (5.0 * side),
        tan.angle,
        _color.withValues(alpha: alpha),
      );
      side = -side;
    }
  }

  // `t` は毎フレーム変化する連続値のため、常に再描画が必要。
  @override
  bool shouldRepaint(_LegFootstepsPainter oldDelegate) => true;
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
  late final AnimationController _pulse;

  bool get _isCurrent => widget.unlocked && !widget.cleared;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
        : Colors.brown.shade300;

    // ロックは「未踏の地」らしくセピア寄せ（白地 → 褪せた羊皮紙色）にして
    // 自然に視線を外させる。Opacity レイヤを使わず色だけで表現（saveLayer 回避）。
    final fill = widget.unlocked ? Colors.white : const Color(0xFFEDE3D2);

    Widget medallion = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: widget.unlocked ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.entry.themeIcon,
        key: ValueKey(stateKey),
        color: color,
        size: 34,
      ),
    );

    if (_isCurrent) {
      medallion = ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 1.12,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
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
                if (_isCurrent) _GlowRing(pulse: _pulse),
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

/// 現在ノードの背後で呼吸する発光リング。`_pulse` に同期して半径と濃さが揺れる。
class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 12 + 10 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

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
