import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/hint_glow.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/miss_bubble.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/trail_sparkle.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

/// 操作が無いまま何秒経過したら未発見の宝を 1 つヒント点滅させるか
/// （アイドル時のみ。タップ/なぞりのたびにカウントはリセットされ、急かさない）。
const Duration _kHintIdleDelay = Duration(seconds: 8);

/// なぞりキラキラを生成する最小移動距離（px）。これ未満の移動では粒を足さず、
/// 粒の密集（描画負荷とちらつき）を抑える。
const double _kTrailSpawnMinDistance = 18.0;

/// 同時に保持するなぞりキラキラの上限。超えたら最古から捨てる
/// （連続ドラッグでも生存ウィジェット数を一定に保つ安全弁）。
const int _kTrailMaxParticles = 24;

/// 正規化 Rect（0.0–1.0）をシーンの実ピクセルへ変換した [Positioned] を作る。
/// 宝とダミーで共通の配置ロジック。[rect] は呼び出し側で
/// [scaledTreasureRect] 済みの矩形を渡す（拡大不要なときのみ素の正規化 Rect）。
Positioned _positioned(Rect rect, Size sceneSize, {required Widget child}) {
  return Positioned(
    left: rect.left * sceneSize.width,
    top: rect.top * sceneSize.height,
    width: rect.width * sceneSize.width,
    height: rect.height * sceneSize.height,
    child: child,
  );
}

class SeekFindScreen extends ConsumerWidget {
  const SeekFindScreen({
    super.key,
    required this.sceneId,
    this.mode = GameMode.easy,
  });

  final String sceneId;
  final GameMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneAsync = ref.watch(sceneProvider(sceneId));
    // 3 モードとも最初から選べるため、URL のモードをそのまま採用する
    // （難易度はおとり量・探索エリアの広さ・点滅で表現し、宝の数は不変）。
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
      body: sceneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (scene) => _SceneView(scene: scene, mode: mode),
      ),
    );
  }
}

class _SceneView extends ConsumerStatefulWidget {
  const _SceneView({required this.scene, required this.mode});

  final SceneDef scene;
  final GameMode mode;

  @override
  ConsumerState<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends ConsumerState<_SceneView>
    with SingleTickerProviderStateMixin {
  bool _completed = false;
  final List<({Offset position, Key key})> _missBubbles = [];

  /// なぞった指先に追従するキラキラ粒子（Easy のみ）。MissBubble と同じく
  /// リストで管理し、各粒は時間経過で自己消滅する。
  final List<({Offset position, Key key, Color color})> _trailSparkles = [];

  /// 直近にキラキラを生成した位置。null は「このなぞりの最初の 1 粒」を表す。
  Offset? _lastTrailSpawn;

  /// 生成済み粒の通し番号。色解決の particleIndex に渡す（にじ拡張の種）。
  int _trailSeq = 0;

  final math.Random _random = math.Random();
  Timer? _hintTimer;
  Timer? _hintClearTimer;
  String? _hintingId;

  /// ハードモードの宝点滅を駆動する共有クロック（0.0–1.0 を周期反復）。
  /// 通常モードでは生成せず null のまま（点滅なし）。
  AnimationController? _blinkClock;

  /// 発見状態のキー。モード間で発見が混ざらないようモードごとに名前空間化する
  /// （Easy はレガシー互換のため素の sceneId）。これは画面セッション内の
  /// インメモリ状態（`foundControllerProvider`）専用で、永続キーとは別物。
  /// `foundControllerProvider` は autoDispose のため画面を離れると破棄され、
  /// Easy↔Normal を行き来しても Easy の素の sceneId が Normal の値を引かない。
  String get _foundKey => switch (widget.mode) {
    GameMode.easy => widget.scene.id,
    GameMode.normal => '${widget.scene.id}#normal',
    GameMode.hard => '${widget.scene.id}#hard',
  };

  /// Normal / Hard はビューポートより大きい探索エリア（パン必須）。
  bool get _isLargeArea => widget.mode != GameMode.easy;

  @override
  void initState() {
    super.initState();
    if (widget.mode == GameMode.hard) {
      _blinkClock = AnimationController(
        vsync: this,
        duration: kBlinkCyclePeriod,
      )..repeat();
    }
    _scheduleHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintClearTimer?.cancel();
    _blinkClock?.dispose();
    super.dispose();
  }

  /// ハードモードでこの宝（[index] 番目）を点滅させるか。
  /// 未発見かつヒント中でないこと、さらに未発見が 2 つ以上あることが条件。
  /// 残り 1 つになったら点滅を止めて常時表示＋常時押せるようにし、「待たないと
  /// 何も押せない」時間帯を作らない（手詰まり防止）。描画と当たり判定の双方が
  /// この同じ条件を参照することで「見えている＝押せる」を保つ。
  bool _isBlinking(int index, Set<String> found, int unfoundCount) {
    if (_blinkClock == null || unfoundCount <= 1) {
      return false;
    }
    final t = widget.scene.targets[index];
    return !found.contains(t.id) && t.id != _hintingId;
  }

  /// ハード点滅で「今まさに消えている」未発見ターゲットの id 集合。
  /// 通常モード（クロック無し）や、ヒント中の宝（強制可視）、残り 1 つの宝
  /// （[_isBlinking] が false）は含めない。
  Set<String> _hiddenTargetIds(Set<String> found) {
    final clock = _blinkClock?.value;
    if (clock == null) {
      return const {};
    }
    final targets = widget.scene.targets;
    final unfoundCount = targets.where((t) => !found.contains(t.id)).length;
    final hidden = <String>{};
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      if (!_isBlinking(i, found, unfoundCount)) {
        continue;
      }
      final opacity = treasureBlinkOpacity(
        slot: i,
        count: targets.length,
        clock: clock,
      );
      if (opacity < kBlinkVisibleThreshold) {
        hidden.add(t.id);
      }
    }
    return hidden;
  }

  /// アイドル計測を仕切り直す。タップ/なぞりのたびに呼ばれ、操作中はヒントを出さない。
  void _scheduleHint() {
    _hintTimer?.cancel();
    _hintTimer = Timer(_kHintIdleDelay, _showHint);
  }

  void _showHint() {
    if (!mounted || _completed || _hintingId != null) {
      return;
    }
    final found = ref.read(foundControllerProvider(_foundKey));
    final id = pickHintTargetId(
      targets: widget.scene.targets,
      foundIds: found,
      random: _random,
    );
    if (id == null) {
      return; // 全て発見済み: 再スケジュールせず自然に停止
    }
    setState(() => _hintingId = id);
    _hintClearTimer?.cancel();
    _hintClearTimer = Timer(kHintGlowDuration, () {
      if (mounted) {
        setState(() => _hintingId = null);
        _scheduleHint(); // 光が消えたら、次のアイドル待ちを再開
      }
    });
  }

  void _addMissBubble(Offset position) {
    final key = UniqueKey();
    setState(() {
      _missBubbles.add((position: position, key: key));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _missBubbles.removeWhere((b) => b.key == key);
        });
      }
    });
  }

  /// なぞり位置に追従するキラキラ粒子を 1 つ生成する（Easy のなぞり中のみ呼ぶ）。
  /// 直近生成位置から [_kTrailSpawnMinDistance] 未満なら間引いて密集を防ぐ。
  void _handlePanTrail(Offset position) {
    final last = _lastTrailSpawn;
    if (last != null && (position - last).distance < _kTrailSpawnMinDistance) {
      return;
    }
    _lastTrailSpawn = position;
    final setting = ref.read(trailSettingControllerProvider);
    final color = resolveTrailColor(setting, particleIndex: _trailSeq);
    _trailSeq++;
    final key = UniqueKey();
    setState(() {
      _trailSparkles.add((position: position, key: key, color: color));
      // 上限を超えたら最古を捨てる（生存ウィジェット数の上限を保証）。
      if (_trailSparkles.length > _kTrailMaxParticles) {
        _trailSparkles.removeAt(0);
      }
    });
    unawaited(
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) {
          setState(() => _trailSparkles.removeWhere((s) => s.key == key));
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final found = ref.watch(foundControllerProvider(_foundKey));
    final unfoundCount = scene.targets
        .where((t) => !found.contains(t.id))
        .length;

    ref.listen(foundControllerProvider(_foundKey), (previous, next) {
      final wasComplete = (previous?.length ?? 0) >= scene.targets.length;
      final nowComplete = next.length >= scene.targets.length;
      if (!wasComplete && nowComplete) {
        unawaited(_handleComplete(scene.id));
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewport = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  // Normal / Hard はビューポートより広い論理キャンバスにして、
                  // パンで表示部分をずらさないと全体が見えないようにする。
                  final sceneSize = _isLargeArea
                      ? Size(
                          viewport.width * kLargeAreaFactor,
                          viewport.height * kLargeAreaFactor,
                        )
                      : viewport;
                  final decoys = decoysForMode(scene, widget.mode);
                  final content = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => _handleHit(d.localPosition, sceneSize),
                    // なぞって探す（パン発見）は Easy のみ。Large area では
                    // ドラッグは InteractiveViewer のパンに割り当てる（タップで発見）。
                    // なぞり中はミスバブルを出さず、代わりに色付きキラキラを追従させる。
                    onPanStart: _isLargeArea
                        ? null
                        : (d) {
                            _lastTrailSpawn = null; // 新しいなぞりの開始
                            _handleHit(
                              d.localPosition,
                              sceneSize,
                              allowMiss: false,
                            );
                            _handlePanTrail(d.localPosition);
                          },
                    onPanUpdate: _isLargeArea
                        ? null
                        : (d) {
                            _handleHit(
                              d.localPosition,
                              sceneSize,
                              allowMiss: false,
                            );
                            _handlePanTrail(d.localPosition);
                          },
                    child: SizedBox(
                      width: sceneSize.width,
                      height: sceneSize.height,
                      child: Stack(
                        key: const ValueKey('scene-content'),
                        fit: StackFit.expand,
                        children: [
                          sceneBackground(scene.id),
                          for (final d in decoys)
                            _positioned(
                              scaledTreasureRect(
                                d.normalizedRect,
                                itemScale: d.scale,
                              ),
                              sceneSize,
                              child: _TargetView(
                                iconId: d.iconId,
                                found: false,
                              ),
                            ),
                          for (var i = 0; i < scene.targets.length; i++)
                            _buildTarget(i, sceneSize, found, unfoundCount),
                          for (final b in _missBubbles)
                            MissBubble(key: b.key, position: b.position),
                          for (final s in _trailSparkles)
                            TrailSparkle(
                              key: s.key,
                              position: s.position,
                              color: s.color,
                            ),
                        ],
                      ),
                    ),
                  );
                  if (!_isLargeArea) {
                    return content;
                  }
                  return InteractiveViewer(
                    constrained: false,
                    minScale: 1.0,
                    maxScale: kLargeAreaMaxScale,
                    child: content,
                  );
                },
              ),
            ),
            CollectionBar(targets: scene.targets, foundIds: found),
          ],
        ),
        if (_completed)
          _ClearOverlay(localeCode: localeCode, onBack: () => context.go('/')),
      ],
    );
  }

  /// 1 つの宝を配置する。ハードモードで [_isBlinking] が真の宝だけ点滅させる。
  Widget _buildTarget(
    int index,
    Size sceneSize,
    Set<String> found,
    int unfoundCount,
  ) {
    final t = widget.scene.targets[index];
    final view = _TargetView(
      key: ValueKey(t.id),
      iconId: t.iconId,
      found: found.contains(t.id),
      hinting: _hintingId == t.id,
    );
    final clock = _blinkClock;
    final blinking = _isBlinking(index, found, unfoundCount);
    return _positioned(
      scaledTreasureRect(t.normalizedRect),
      sceneSize,
      child: clock == null || !blinking
          ? view
          : _BlinkingTarget(
              clock: clock,
              slot: index,
              count: widget.scene.targets.length,
              child: view,
            ),
    );
  }

  Future<void> _handleComplete(String sceneId) async {
    if (_completed) return; // 二重発火ガード（連続通知でも完了処理は一度だけ）
    final progress = ref.read(progressRepositoryProvider);
    await completeScene(progress, widget.mode, sceneId);
    await ref.read(audioServiceProvider).playComplete();
    if (mounted) {
      _hintTimer?.cancel();
      _blinkClock?.stop(); // 完了後は点滅を止める（全て発見済みなので不要）
      setState(() => _completed = true);
    }
  }

  /// [allowMiss] が false のとき（なぞり中）はミスバブルを出さない。
  /// なぞりの視覚フィードバックは色付きキラキラ（[_handlePanTrail]）が担うため。
  void _handleHit(
    Offset localPosition,
    Size sceneSize, {
    bool allowMiss = true,
  }) {
    _scheduleHint(); // 操作があった = アイドルではない。ヒント待ちをリセット
    final scene = widget.scene;
    final found = ref.read(foundControllerProvider(_foundKey));
    final hidden = _hiddenTargetIds(found);
    final hitId = findHitTargetId(
      scenePoint: localPosition,
      sceneSize: sceneSize,
      targets: scene.targets,
      foundIds: found,
      hiddenIds: hidden,
    );
    if (hitId == null) {
      // 消失中の宝の上をタップしたときは無反応（罰なし）。空の場所だけミスバブル。
      final onHidden = isPointOnHiddenTarget(
        scenePoint: localPosition,
        sceneSize: sceneSize,
        targets: scene.targets,
        hiddenIds: hidden,
      );
      if (allowMiss && !onHidden) {
        _addMissBubble(localPosition);
      }
      return;
    }
    ref.read(foundControllerProvider(_foundKey).notifier).markFound(hitId);
    HapticFeedback.lightImpact();
    ref.read(audioServiceProvider).playFound();
  }
}

class _TargetView extends StatelessWidget {
  const _TargetView({
    super.key,
    required this.iconId,
    required this.found,
    this.hinting = false,
  });

  final String iconId;
  final bool found;
  final bool hinting;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      // Clip.none lets FoundBurst sparks radiate beyond the target bounds
      clipBehavior: Clip.none,
      children: [
        if (found)
          RepaintBoundary(child: _FoundGlow(color: targetColor(iconId))),
        if (!found && hinting)
          RepaintBoundary(child: HintGlow(color: targetColor(iconId))),
        FittedBox(
          fit: BoxFit.contain,
          child: found
              ? Icon(targetIcon(iconId), color: targetColor(iconId))
              : UnfoundTreasureIcon(iconId: iconId),
        ),
        if (found) FoundBurst(color: targetColor(iconId)),
      ],
    );
  }
}

/// ハードモードの宝点滅ラッパ。共有クロックに合わせて [Opacity] のみを更新し、
/// [child]（宝の見た目）は再構築しない。点滅させるかどうかは呼び出し側
/// （[_SceneViewState._isBlinking]）が判定済みで、このウィジェットは常に点滅する。
/// [RepaintBoundary] で毎フレームの再描画をシーン全体から隔離する
/// （兄弟の [_FoundGlow] / [HintGlow] と同じ方針）。
class _BlinkingTarget extends StatelessWidget {
  const _BlinkingTarget({
    required this.clock,
    required this.slot,
    required this.count,
    required this.child,
  });

  final Animation<double> clock;
  final int slot;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: clock,
        child: child,
        builder: (context, ch) {
          final opacity = treasureBlinkOpacity(
            slot: slot,
            count: count,
            clock: clock.value,
          );
          return Opacity(opacity: opacity, child: ch);
        },
      ),
    );
  }
}

class _FoundGlow extends StatefulWidget {
  const _FoundGlow({required this.color});

  final Color color;

  @override
  State<_FoundGlow> createState() => _FoundGlowState();
}

class _FoundGlowState extends State<_FoundGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0.0 → 1.0 → 0.0 (reverse)
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45 * t),
                blurRadius: 16 + 8 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────
// Clear overlay: full-screen キラキラ + message + back button
// ──────────────────────────────────────────

class _ClearOverlay extends StatefulWidget {
  const _ClearOverlay({required this.localeCode, required this.onBack});

  final String localeCode;
  final VoidCallback onBack;

  @override
  State<_ClearOverlay> createState() => _ClearOverlayState();
}

class _ClearOverlayState extends State<_ClearOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Normalized [x, y, phaseOffset] for twinkling stars. Explicit List<List<double>>
  // type prevents Dart inferring List<List<num>> from the literal.
  static const List<List<double>> _kStars = [
    [0.06, 0.08, 0.0],
    [0.22, 0.05, 0.3],
    [0.42, 0.12, 0.6],
    [0.62, 0.06, 0.1],
    [0.80, 0.10, 0.5],
    [0.93, 0.04, 0.8],
    [0.14, 0.24, 0.2],
    [0.36, 0.20, 0.7],
    [0.58, 0.27, 0.4],
    [0.78, 0.22, 0.9],
    [0.04, 0.44, 0.6],
    [0.28, 0.40, 0.1],
    [0.52, 0.38, 0.3],
    [0.74, 0.45, 0.8],
    [0.94, 0.42, 0.2],
    [0.10, 0.62, 0.5],
    [0.35, 0.68, 0.0],
    [0.66, 0.60, 0.7],
    [0.86, 0.65, 0.4],
    [0.20, 0.80, 0.9],
    [0.50, 0.84, 0.2],
    [0.72, 0.78, 0.6],
    [0.90, 0.88, 0.1],
  ];

  @override
  void dispose() {
    _entry.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _entry,
        child: Stack(
          children: [
            // Dark translucent backdrop — SizedBox.expand prevents the
            // DecoratedBox from collapsing to zero under loose Stack constraints.
            const SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000830), Color(0xCC001040)],
                  ),
                ),
              ),
            ),
            // Twinkling stars
            AnimatedBuilder(
              animation: _sparkle,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparklePainter(_sparkle.value, _kStars),
                  size: Size.infinite,
                );
              },
            ),
            // Center message + button
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _entry,
                  curve: Curves.elasticOut,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingStarIcon(controller: _sparkle),
                    const SizedBox(height: 20),
                    Text(
                      tr(widget.localeCode, 'seek.complete'),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 16,
                            color: Colors.amber,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    KidsButton(
                      label: tr(widget.localeCode, 'seek.toMap'),
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.t, this.stars);

  final double t;
  final List<List<double>> stars;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final phase = (t + s[2]) % 1.0;
      final brightness = math.sin(phase * math.pi);
      final opacity = (brightness * 0.85).clamp(0.0, 1.0);
      final r = 3.0 + brightness * 7.0;
      final cx = s[0] * size.width;
      final cy = s[1] * size.height;
      // Outer glow
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.8,
        Paint()..color = Colors.amber.withValues(alpha: opacity * 0.35),
      );
      // Core dot
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = Colors.amber.withValues(alpha: opacity),
      );
      // White center
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.38,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

class _PulsingStarIcon extends AnimatedWidget {
  const _PulsingStarIcon({required this.controller})
    : super(listenable: controller);

  // Typed field avoids unsafe `as AnimationController` cast in build.
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + math.sin(controller.value * 2 * math.pi) * 0.15;
    return Transform.scale(
      scale: scale,
      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 80),
    );
  }
}
