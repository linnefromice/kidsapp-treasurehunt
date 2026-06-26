import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/hint_glow.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';

/// 宝（またはおとり）1 つの見た目。発見前は影絵 or カバー絵（A1）、発見で
/// カラー＋発見バースト。ヒント中はグロー。
///
/// 仕上げ演出:
/// - 接地シャドウ: 宝を背景に“置いた”ように馴染ませる（背景の上・宝の下）。
/// - アイドル揺れ: 未発見の宝/おとりをごく低振幅で揺らす（共有クロック・位相違い）。
/// - リビール: 発見時、被っていたカバー/影絵が「ポンッ」と開いて宝が現れる。
class TargetView extends StatefulWidget {
  const TargetView({
    super.key,
    required this.iconId,
    required this.found,
    this.hinting = false,
    this.burstIntensity = 1.0,
    this.coverIconId,
    this.idleClock,
    this.idlePhase = 0,
  });

  final String iconId;
  final bool found;
  final bool hinting;

  /// 発見バーストの派手さ（連鎖 A5 / ラスト B6）。おとり・未発見では未使用。
  final double burstIntensity;

  /// めくり露出（A1）の「かぶせもの」アイコン id。未発見の間はこのカバー絵を
  /// 影絵の代わりに表示する。発見するとめくれて宝が現れる。
  final String? coverIconId;

  /// 共有アイドルクロック（0..1 を周期反復）。null なら揺れない（点滅中など）。
  final Animation<double>? idleClock;

  /// アイテムごとの位相オフセット（全アイテムが同期して揺れないようにずらす）。
  final double idlePhase;

  @override
  State<TargetView> createState() => _TargetViewState();
}

class _TargetViewState extends State<TargetView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;

  /// 発見直前に被さっていたカバー id（影絵リビールなら null）。開く対象。
  String? _openingCover;
  bool _wasCovered = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant TargetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 未発見 → 発見 に切り替わった瞬間にリビールを再生する。
    if (!oldWidget.found && widget.found) {
      _openingCover = oldWidget.coverIconId;
      _wasCovered = true;
      _reveal.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.coverIconId;
    return Stack(
      alignment: Alignment.center,
      // Clip.none lets FoundBurst sparks and the reveal puff radiate outward.
      clipBehavior: Clip.none,
      children: [
        // シーンに馴染ませる接地シャドウ（背景の上・宝の下）。
        const Align(
          alignment: Alignment(0, 0.95),
          child: FractionallySizedBox(
            widthFactor: 0.6,
            heightFactor: 0.16,
            child: _ContactShadow(),
          ),
        ),
        if (widget.found)
          RepaintBoundary(child: _FoundGlow(color: targetColor(widget.iconId))),
        if (!widget.found && widget.hinting)
          // カバー表示中は、見えているカバーの色で光らせる（誘目の一致）。
          RepaintBoundary(
            child: HintGlow(
              color: cover != null
                  ? targetColor(cover)
                  : targetColor(widget.iconId),
            ),
          ),
        FittedBox(fit: BoxFit.contain, child: _glyphArea(cover)),
        if (widget.found)
          FoundBurst(
            color: targetColor(widget.iconId),
            intensity: widget.burstIntensity,
          ),
      ],
    );
  }

  Widget _glyphArea(String? cover) {
    if (!widget.found) {
      // 未発見: カバー絵 or 影絵。アイドルクロックがあれば微振幅で揺らす。
      final glyph = cover != null
          ? TreasureGlyph(iconId: cover, found: true)
          : UnfoundTreasureIcon(iconId: widget.iconId);
      final clock = widget.idleClock;
      if (clock == null) return glyph;
      return _IdleMotion(clock: clock, phase: widget.idlePhase, child: glyph);
    }
    // 発見: 宝が「ポンッ」と現れ、被っていたカバー/影絵が開いて消える。
    final treasure = TreasureGlyph(iconId: widget.iconId, found: true);
    if (!_wasCovered) return treasure;
    return AnimatedBuilder(
      animation: _reveal,
      child: treasure,
      builder: (context, treasureChild) {
        final v = _reveal.value;
        // 宝はオーバーシュート付きで現れる。開くカバー/影絵は拡大しながら消える。
        final pop = Curves.easeOutBack.transform(v);
        final opening = _openingCover != null
            ? TreasureGlyph(iconId: _openingCover!, found: true)
            : UnfoundTreasureIcon(iconId: widget.iconId);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(scale: v >= 1 ? 1.0 : pop, child: treasureChild),
            if (v < 1)
              Opacity(
                opacity: 1 - v,
                child: Transform.scale(scale: 1 + 0.7 * v, child: opening),
              ),
          ],
        );
      },
    );
  }
}

/// ごく低振幅のアイドル揺れ（上下バブ＋微回転）。サイズに依らないよう
/// [FractionalTranslation] で child の割合だけ動かす。[phase] で同期を外す。
/// 0–5 歳に配慮し、振幅は「気づくか気づかないか」程度に抑えている。
class _IdleMotion extends StatelessWidget {
  const _IdleMotion({
    required this.clock,
    required this.phase,
    required this.child,
  });

  final Animation<double> clock;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: clock,
        child: child,
        builder: (context, ch) {
          final a = 2 * math.pi * (clock.value + phase);
          final dy = 0.03 * math.sin(a);
          final rot = 0.04 * math.sin(a * 0.8);
          return Transform.rotate(
            angle: rot,
            child: FractionalTranslation(translation: Offset(0, dy), child: ch),
          );
        },
      ),
    );
  }
}

/// 宝をシーンに“置いた”ように見せる、やわらかい楕円の接地シャドウ。
class _ContactShadow extends StatelessWidget {
  const _ContactShadow();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _ContactShadowPainter());
}

class _ContactShadowPainter extends CustomPainter {
  const _ContactShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x33000000), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(_ContactShadowPainter oldDelegate) => false;
}

/// ハードモードの宝点滅ラッパ。共有クロックに合わせて [Opacity] のみを更新し、
/// [child]（宝の見た目）は再構築しない。点滅させるかどうかは呼び出し側が判定済みで、
/// このウィジェットは常に点滅する。[RepaintBoundary] で毎フレームの再描画を隔離する。
class BlinkingTarget extends StatelessWidget {
  const BlinkingTarget({
    super.key,
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
