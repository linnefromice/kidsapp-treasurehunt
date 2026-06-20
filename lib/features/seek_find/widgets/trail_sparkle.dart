import 'package:flutter/material.dart';

/// 粒の直径（dp）。
const double _kSparkleSize = 18.0;

/// Easy モードでなぞった指先に追従して出る、一瞬の小さなキラキラ粒子。
///
/// 1 粒 = 1 ウィジェット。生成直後に膨らんで消える短い演出だけを担い、
/// リストからの除去は親（`_SceneViewState`）が `MissBubble` と同じ方式で行う。
class TrailSparkle extends StatefulWidget {
  const TrailSparkle({super.key, required this.position, required this.color});

  /// シーン座標上の生成位置（粒の中心）。
  final Offset position;

  /// 粒の色（設定で選んだトレイル色から解決済み）。
  final Color color;

  @override
  State<TrailSparkle> createState() => _TrailSparkleState();
}

class _TrailSparkleState extends State<TrailSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.6,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.9), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.0), weight: 80),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 毎フレームの再描画をシーン全体から隔離する（兄弟の _FoundGlow/HintGlow と同方針）。
    // FadeTransition/ScaleTransition は AnimatedBuilder+Opacity より合成コストが低い。
    return Positioned(
      left: widget.position.dx - _kSparkleSize / 2,
      top: widget.position.dy - _kSparkleSize / 2,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: _kSparkleSize,
                height: _kSparkleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  // 明るい背景でも輪郭が見えるよう薄い暗色のフチを足す
                  // （しろ等の淡色でも視認できる。キッズ UX のコントラスト確保）。
                  border: Border.all(color: const Color(0x66000000)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
