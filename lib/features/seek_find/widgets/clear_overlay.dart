import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

/// シーンクリアの全画面セレモニー: 暗幕＋またたく星＋一度きりの紙吹雪（B1）＋
/// 「みつけたね！」メッセージ＋地図に戻るボタン。
class ClearOverlay extends StatefulWidget {
  const ClearOverlay({
    super.key,
    required this.localeCode,
    required this.onBack,
  });

  final String localeCode;
  final VoidCallback onBack;

  @override
  State<ClearOverlay> createState() => _ClearOverlayState();
}

class _ClearOverlayState extends State<ClearOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // クリアの瞬間に一度だけ降る紙吹雪（B1: セレモニー強化）。山場だけ豪華に
  // し、常時はループさせない（calm 哲学・過剰刺激を避ける）。
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  // 紙吹雪 1 片: [startX(0–1), 色index(0–5), 横ゆれ量(-1–1), 大きさ(0.7–1.3), 開始遅延(0–0.35)]
  static const List<List<double>> _kConfetti = [
    [0.05, 0, 0.8, 1.1, 0.00],
    [0.14, 2, -0.6, 0.9, 0.10],
    [0.23, 4, 0.5, 1.2, 0.05],
    [0.32, 1, -0.9, 0.8, 0.18],
    [0.41, 3, 0.7, 1.0, 0.02],
    [0.50, 5, -0.4, 1.3, 0.12],
    [0.59, 0, 0.9, 0.9, 0.07],
    [0.68, 2, -0.7, 1.1, 0.20],
    [0.77, 4, 0.6, 0.8, 0.03],
    [0.86, 1, -0.8, 1.2, 0.15],
    [0.95, 3, 0.4, 1.0, 0.09],
    [0.10, 5, -0.5, 1.1, 0.25],
    [0.19, 1, 0.8, 0.9, 0.30],
    [0.28, 3, -0.6, 1.2, 0.08],
    [0.37, 0, 0.7, 0.8, 0.22],
    [0.46, 2, -0.9, 1.0, 0.04],
    [0.55, 4, 0.5, 1.3, 0.17],
    [0.64, 1, -0.4, 0.9, 0.28],
    [0.73, 5, 0.9, 1.1, 0.06],
    [0.82, 0, -0.7, 0.8, 0.13],
    [0.91, 2, 0.6, 1.2, 0.24],
    [0.01, 4, -0.8, 1.0, 0.11],
    [0.43, 5, 0.5, 0.9, 0.33],
    [0.61, 3, -0.6, 1.1, 0.19],
  ];

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
    _confetti.dispose();
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
            // Twinkling stars（毎フレーム再描画をオーバーレイ全体から隔離）
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _sparkle,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SparklePainter(_sparkle.value, _kStars),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            // Falling confetti (plays once)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(_confetti.value, _kConfetti),
                    size: Size.infinite,
                  );
                },
              ),
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

/// クリア時に一度だけ上から降る紙吹雪。各片は回転しながら落下し、
/// 終盤でフェードアウトする。[t] は 0→1 の一回再生進捗。
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.t, this.pieces);

  final double t;
  final List<List<double>> pieces;

  static const List<Color> _palette = [
    Color(0xFFFFC107), // amber
    Color(0xFFE91E63), // pink
    Color(0xFF42A5F5), // sky
    Color(0xFF66BB6A), // green
    Color(0xFFAB47BC), // purple
    Color(0xFFFF7043), // orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final startX = p[0];
      final color = _palette[p[1].toInt() % _palette.length];
      final drift = p[2];
      final sizeF = p[3];
      final delay = p[4];

      if (delay >= 1.0) {
        continue; // ゼロ除算ガード（将来データに delay=1.0 が混じっても安全）
      }
      // 開始遅延を抜いた各片の進捗。
      final local = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (local <= 0.0) {
        continue;
      }
      // 上から下へ落下（画面外まで）。横はゆっくり左右に揺れる。
      final y = (-0.05 + local * 1.15) * size.height;
      final x =
          (startX + drift * 0.06 * math.sin(local * math.pi * 2 + p[1])) *
          size.width;
      // フェードイン（0–0.1）→ フェードアウト（0.8–1.0）。
      final opacity = (local < 0.1
          ? local / 0.1
          : (local > 0.8 ? (1.0 - local) / 0.2 : 1.0));
      final w = 10.0 * sizeF;
      final h = 6.0 * sizeF;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((startX * 6 + local * 8) % (2 * math.pi));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || old.pieces != pieces;
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
