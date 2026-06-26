import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';

/// 祝福のフルスクリーン演出（climax）。レア宝の発見（A-2）と称号バッチ取得（B-3）で
/// 共有する。暗転スクリム → 中央へズームイン → 放射状の光線（回転）→ きらめき →
/// タイトル/サブタイトル。タップで閉じ、一定時間で自動的に閉じる。SDK のみ。
///
/// 発見の瞬間に多感覚フィードバックを集中する原則に沿う（レア=climax は派手でよい）。
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.iconId,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
    this.accent = const Color(0xFFFFC400),
    this.duration = const Duration(milliseconds: 2600),
  });

  /// 中央に大きく出す宝/バッジのアイコン id（SVG）。
  final String iconId;

  /// 大きな見出し（例「✨ とくべつ！ ✨」「バッチ ゲット！」）。
  final String title;

  /// 小さな添え書き（例 レア名 / バッジ名）。
  final String subtitle;

  /// 光線・見出しのアクセント色。
  final Color accent;

  /// 閉じられたとき（タップ or 自動）に呼ばれる。親が overlay を外す。
  final VoidCallback onDismiss;

  /// 自動で閉じるまでの時間。
  final Duration duration;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..forward();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // 0.0–0.22 で立ち上げ、終盤 0.85–1.0 でフェードアウト。
            final intro = (t / 0.22).clamp(0.0, 1.0);
            final outro = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
            final vis = (intro * (1 - outro)).clamp(0.0, 1.0);
            final pop = Curves.easeOutBack.transform(intro);
            return Opacity(
              opacity: vis,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 暗転スクリム（中央を少し明るく抜く）。
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  // 放射状の光線（ゆっくり回転）。
                  Center(
                    child: CustomPaint(
                      size: Size.square(
                        MediaQuery.sizeOf(context).shortestSide,
                      ),
                      painter: _RaysPainter(
                        t: t,
                        color: widget.accent,
                        opacity: 0.5 * vis,
                      ),
                    ),
                  ),
                  // 中央のアイコン＋見出し。
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: pop,
                          child: SizedBox(
                            width:
                                MediaQuery.sizeOf(context).shortestSide * 0.36,
                            height:
                                MediaQuery.sizeOf(context).shortestSide * 0.36,
                            child: TreasureGlyph(
                              iconId: widget.iconId,
                              found: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Banner(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          accent: widget.accent,
                          scale: pop,
                        ),
                      ],
                    ),
                  ),
                  // きらめき（中央周囲で明滅）。
                  ..._sparkles(t, vis),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sparkles(double t, double vis) {
    final size = MediaQuery.sizeOf(context);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.3;
    const seeds = [
      [0.0, 1.0],
      [0.6, 0.8],
      [1.3, 1.15],
      [2.1, 0.7],
      [2.8, 1.0],
      [3.7, 0.9],
      [4.5, 1.2],
      [5.4, 0.75],
    ];
    return [
      for (final s in seeds)
        Builder(
          builder: (_) {
            final ang = s[0];
            final rr = r * s[1];
            final x = cx + rr * math.cos(ang);
            final y = cy + rr * math.sin(ang);
            final tw = (0.5 + 0.5 * math.sin(2 * math.pi * (2 * t + s[0])))
                .clamp(0.0, 1.0);
            final sz = 10.0 + 8.0 * tw;
            return Positioned(
              left: x - sz / 2,
              top: y - sz / 2,
              child: Opacity(
                opacity: tw * vis,
                child: Icon(Icons.auto_awesome, size: sz, color: widget.accent),
              ),
            );
          },
        ),
    ];
  }
}

/// 見出し＋添え書きのバナー。
class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.scale,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 中央から伸びる放射状の光線。[t]（0..1）でゆっくり回転、[opacity] で全体の濃さ。
class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.t, required this.color, required this.opacity});

  final double t;
  final Color color;
  final double opacity;

  static const int _count = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.62;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * math.pi); // 半回転をゆっくり
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (var i = 0; i < _count; i++) {
      final a = (2 * math.pi / _count) * i;
      const half = 0.045 * math.pi; // 光線の太さ（角度）
      final p1 = Offset(math.cos(a - half), math.sin(a - half)) * 8;
      final p2 = Offset(math.cos(a - half), math.sin(a - half)) * radius;
      final p3 = Offset(math.cos(a + half), math.sin(a + half)) * radius;
      final p4 = Offset(math.cos(a + half), math.sin(a + half)) * 8;
      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.opacity != opacity ||
      oldDelegate.color != color;
}
