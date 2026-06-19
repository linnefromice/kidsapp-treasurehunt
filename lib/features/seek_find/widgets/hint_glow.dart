import 'package:flutter/material.dart';

/// ヒントの光が 1 回点滅する時間。画面側のクリア遅延と共有する。
const Duration kHintGlowDuration = Duration(milliseconds: 1400);

/// 未発見の宝を「わずかに」一度だけ光らせる控えめなヒント。急かさない・罰しない。
class HintGlow extends StatefulWidget {
  const HintGlow({super.key, required this.color});

  final Color color;

  @override
  State<HintGlow> createState() => _HintGlowState();
}

class _HintGlowState extends State<HintGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: kHintGlowDuration,
  )..forward();

  // フェードイン → 保持 → フェードアウト の一回きり（0→1→1→0）。
  late final Animation<double> _t = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 * v),
                blurRadius: 12 + 10 * v,
                spreadRadius: 1 + 3 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}
