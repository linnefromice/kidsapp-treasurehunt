import 'package:flutter/material.dart';

/// 外れタップ時に一瞬表示される控えめな泡エフェクト。失敗を罰しない。
class MissBubble extends StatefulWidget {
  const MissBubble({super.key, required this.position});

  /// シーン座標上のタップ位置
  final Offset position;

  @override
  State<MissBubble> createState() => _MissBubbleState();
}

class _MissBubbleState extends State<MissBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 0.3, end: 1.2)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.55), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 50),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    return Positioned(
      left: widget.position.dx - size / 2,
      top: widget.position.dy - size / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFB3D4FF), // 淡い水色
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
