import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';

/// 収集済みの宝を「大きく見て愛でる」ビューア（#3）。タップで開き、もう一度タップ
/// またはどこかをタップで閉じる。ふわっと揺れ＋きらめきで眺める楽しさを足す。
Future<void> showTreasureViewer(
  BuildContext context, {
  required String iconId,
  required String name,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => _TreasureViewer(iconId: iconId, name: name),
    transitionBuilder: (_, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _TreasureViewer extends StatefulWidget {
  const _TreasureViewer({required this.iconId, required this.name});

  final String iconId;
  final String name;

  @override
  State<_TreasureViewer> createState() => _TreasureViewerState();
}

class _TreasureViewerState extends State<_TreasureViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.sizeOf(context).shortestSide * 0.5;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = _c.value;
                final dy = 0.025 * math.sin(2 * math.pi * t);
                final rot = 0.03 * math.sin(2 * math.pi * t * 0.8);
                return SizedBox(
                  width: big,
                  height: big,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      ..._sparkles(big, t),
                      Transform.rotate(
                        angle: rot,
                        child: FractionalTranslation(
                          translation: Offset(0, dy),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: TreasureGlyph(iconId: widget.iconId, found: true),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade400, width: 3),
              ),
              child: Text(
                widget.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sparkles(double big, double t) {
    const seeds = [
      [0.3, 0.95],
      [1.4, 0.8],
      [2.5, 1.05],
      [3.6, 0.85],
      [4.8, 1.0],
      [5.6, 0.75],
    ];
    final c = big / 2;
    final r = big * 0.46;
    return [
      for (final s in seeds)
        Builder(
          builder: (_) {
            final x = c + r * s[1] * math.cos(s[0]);
            final y = c + r * s[1] * math.sin(s[0]);
            final tw = (0.5 + 0.5 * math.sin(2 * math.pi * (2 * t + s[0])))
                .clamp(0.0, 1.0);
            final sz = 9.0 + 8.0 * tw;
            return Positioned(
              left: x - sz / 2,
              top: y - sz / 2,
              child: Opacity(
                opacity: tw,
                child: Icon(
                  Icons.auto_awesome,
                  size: sz,
                  color: Colors.amber.shade400,
                ),
              ),
            );
          },
        ),
    ];
  }
}
