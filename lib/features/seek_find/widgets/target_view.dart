import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_logic.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/hint_glow.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';

/// 宝（またはおとり）1 つの見た目。発見前は影絵 or カバー絵（A1）、発見で
/// カラー＋発見バースト。ヒント中はグロー。
class TargetView extends StatelessWidget {
  const TargetView({
    super.key,
    required this.iconId,
    required this.found,
    this.hinting = false,
    this.burstIntensity = 1.0,
    this.coverIconId,
  });

  final String iconId;
  final bool found;
  final bool hinting;

  /// 発見バーストの派手さ（連鎖 A5 / ラスト B6）。おとり・未発見では未使用。
  final double burstIntensity;

  /// めくり露出（A1）の「かぶせもの」アイコン id。未発見の間はこのカバー絵を
  /// 影絵の代わりに表示する。発見すると消えて宝が現れる（＝めくれる演出）。
  final String? coverIconId;

  @override
  Widget build(BuildContext context) {
    final cover = coverIconId;
    return Stack(
      alignment: Alignment.center,
      // Clip.none lets FoundBurst sparks radiate beyond the target bounds
      clipBehavior: Clip.none,
      children: [
        if (found)
          RepaintBoundary(child: _FoundGlow(color: targetColor(iconId))),
        if (!found && hinting)
          // カバー表示中は、画面に見えているカバーの色で光らせる（誘目の一致）。
          RepaintBoundary(
            child: HintGlow(
              color: cover != null ? targetColor(cover) : targetColor(iconId),
            ),
          ),
        FittedBox(
          fit: BoxFit.contain,
          child: found
              ? TreasureGlyph(iconId: iconId, found: true)
              : (cover != null
                    // 未発見かつカバー有り: 影絵でなく「かぶせもの」を見せる（A1）。
                    ? TreasureGlyph(iconId: cover, found: true)
                    : UnfoundTreasureIcon(iconId: iconId)),
        ),
        if (found)
          FoundBurst(color: targetColor(iconId), intensity: burstIntensity),
      ],
    );
  }
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
