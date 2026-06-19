import 'dart:math' as math;
import 'package:flutter/material.dart';

/// シーン背景に重ねる「生きた背景」アニメ層。
///
/// 既存の静止画 painter（`scene_background.dart`）には一切触れず、その上に
/// 低振幅・緩ループの環境アニメ（漂う雲・舞う光・ホタル・昇る泡・降る雪・星の瞬き）を
/// 重ねる。1 本の [AnimationController] が `t`(0..1) を回し、全粒子が共有する。
/// `RepaintBoundary` で静止画層と分離するため、静止画は再描画されない。
///
/// SDK のみ（`CustomPainter` + `dart:ui`）・アセット不要・追加 package 不要。

/// 環境粒子の種類。
enum AmbientKind {
  /// ふわっと横に流れる雲。
  drift,

  /// ゆっくり漂う微粒子（花粉・砂塵）。
  mote,

  /// ゆらゆら漂い明滅するホタル。
  firefly,

  /// 下から上へ昇る泡。
  bubble,

  /// 上から下へ降る雪。
  snow,

  /// その場で瞬く星。
  twinkle,
}

/// 1 シーンに重ねる粒子群の設定（不変）。1 シーンに複数重ねられる。
@immutable
class AmbientSpec {
  const AmbientSpec({
    required this.kind,
    required this.count,
    required this.color,
    required this.seed,
  });

  final AmbientKind kind;
  final int count;
  final Color color;

  /// 粒子の初期配置を決める決定論的シード（`Math.random` 非依存・再現可能）。
  final int seed;
}

/// 1 シーンの粒子総数の上限（性能・Kids 規制ガイド H 章）。
const int kAmbientMaxParticlesPerScene = 30;

/// シーン別の環境アニメ設定。未知の id では空（アニメ無し）。
List<AmbientSpec> ambientSpecsFor(String sceneId) => switch (sceneId) {
  'scene01' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 101,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 8,
      color: Color(0xFFFFF6C8),
      seed: 102,
    ),
  ],
  'scene02' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 201,
    ),
  ],
  'scene03' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 14,
      color: Color(0xFFFFFFFF),
      seed: 301,
    ),
  ],
  'scene04' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 3,
      color: Color(0xCCFFFFFF),
      seed: 401,
    ),
  ],
  'scene05' => const [
    AmbientSpec(
      kind: AmbientKind.firefly,
      count: 7,
      color: Color(0xFFCDEB6B),
      seed: 501,
    ),
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 10,
      color: Color(0xFFFFFDE7),
      seed: 502,
    ),
  ],
  'scene06' => const [
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 2,
      color: Color(0xB3FFE0B2),
      seed: 601,
    ),
    AmbientSpec(
      kind: AmbientKind.mote,
      count: 6,
      color: Color(0xFFFFE0B2),
      seed: 602,
    ),
  ],
  'scene07' => const [
    AmbientSpec(
      kind: AmbientKind.twinkle,
      count: 18,
      color: Color(0xFFFFFFFF),
      seed: 701,
    ),
    AmbientSpec(
      kind: AmbientKind.drift,
      count: 1,
      color: Color(0x33B39DDB),
      seed: 702,
    ),
  ],
  'scene08' => const [
    AmbientSpec(
      kind: AmbientKind.bubble,
      count: 14,
      color: Color(0xFFE1F5FE),
      seed: 801,
    ),
  ],
  'scene09' => const [
    AmbientSpec(
      kind: AmbientKind.snow,
      count: 26,
      color: Color(0xFFFFFFFF),
      seed: 901,
    ),
  ],
  _ => const [],
};

/// シーン背景に重ねる環境アニメ層を返す。設定が無ければ何も描かない。
Widget sceneAmbient(String sceneId) {
  final specs = ambientSpecsFor(sceneId);
  if (specs.isEmpty) return const SizedBox.shrink();
  return AmbientLayer(specs: specs);
}

/// 共有ティッカーで全粒子を駆動する環境アニメ層。
class AmbientLayer extends StatefulWidget {
  const AmbientLayer({super.key, required this.specs});

  final List<AmbientSpec> specs;

  @override
  State<AmbientLayer> createState() => _AmbientLayerState();
}

class _AmbientLayerState extends State<AmbientLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_AmbientGroup> _groups;

  @override
  void initState() {
    super.initState();
    // 粒子の初期配置は一度だけ決定論的に生成し、以降は t だけで動かす。
    _groups = [
      for (final spec in widget.specs)
        _AmbientGroup(spec, _buildParticles(spec)),
    ];
    // 18 秒で 1 周。雲の横断・雪の落下も 1 周＝緩やかなループになる。
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _AmbientPainter(t: _controller.value, groups: _groups),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 1 つの spec とその粒子配列の束。
class _AmbientGroup {
  const _AmbientGroup(this.spec, this.particles);

  final AmbientSpec spec;
  final List<_Particle> particles;
}

/// 個々の粒子の不変な基準値。動きは `t` から都度計算する。
/// 各フィールドの解釈は kind によって異なる（位置=正規化 0..1、半径=最短辺比、
/// `phase`=位相 0..1、`drift`=振幅/基準明度など kind 固有の係数）。
class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.drift,
  });

  final double x;
  final double y;
  final double r;
  final double phase;
  final double drift;
}

List<_Particle> _buildParticles(AmbientSpec spec) {
  final rnd = math.Random(spec.seed);
  return [for (var i = 0; i < spec.count; i++) _makeParticle(spec.kind, rnd)];
}

_Particle _makeParticle(AmbientKind kind, math.Random rnd) {
  double range(double lo, double hi) => lo + rnd.nextDouble() * (hi - lo);
  return switch (kind) {
    AmbientKind.drift => _Particle(
      x: rnd.nextDouble(),
      y: range(0.04, 0.4),
      r: range(0.08, 0.15),
      phase: rnd.nextDouble(),
      drift: range(0.6, 1.0),
    ),
    AmbientKind.mote => _Particle(
      x: rnd.nextDouble(),
      y: range(0.2, 0.85),
      r: range(0.004, 0.009),
      phase: rnd.nextDouble(),
      drift: range(0.01, 0.03),
    ),
    AmbientKind.firefly => _Particle(
      x: range(0.08, 0.92),
      y: range(0.4, 0.88),
      r: range(0.006, 0.012),
      phase: rnd.nextDouble(),
      drift: range(0.02, 0.05),
    ),
    AmbientKind.bubble => _Particle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: range(0.01, 0.025),
      phase: rnd.nextDouble(),
      drift: range(0.01, 0.03),
    ),
    AmbientKind.snow => _Particle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: range(0.004, 0.012),
      phase: rnd.nextDouble(),
      drift: range(0.01, 0.04),
    ),
    AmbientKind.twinkle => _Particle(
      x: range(0.04, 0.96),
      y: range(0.03, 0.5),
      r: range(0.004, 0.009),
      phase: rnd.nextDouble(),
      drift: range(0.3, 0.7),
    ),
  };
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.t, required this.groups});

  final double t;
  final List<_AmbientGroup> groups;

  static const double _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    for (final g in groups) {
      for (final p in g.particles) {
        switch (g.spec.kind) {
          case AmbientKind.drift:
            _paintDrift(canvas, size, s, p, g.spec.color);
          case AmbientKind.mote:
            _paintMote(canvas, size, s, p, g.spec.color);
          case AmbientKind.firefly:
            _paintFirefly(canvas, size, s, p, g.spec.color);
          case AmbientKind.bubble:
            _paintBubble(canvas, size, s, p, g.spec.color);
          case AmbientKind.snow:
            _paintSnow(canvas, size, s, p, g.spec.color);
          case AmbientKind.twinkle:
            _paintTwinkle(canvas, size, s, p, g.spec.color);
        }
      }
    }
  }

  /// 横断系（雲）の seamless ループ: t の 1 周で左外 → 右外を 1 往復。
  /// margin 分だけ画面外に余白を取り、巻き戻りは画面外で起きる。
  void _paintDrift(Canvas c, Size size, double s, _Particle p, Color color) {
    const margin = 0.3;
    final x01 = (p.x + t) % 1.0;
    final cx = (x01 * (1 + 2 * margin) - margin) * size.width;
    final cy = p.y * size.height;
    final r = p.r * s;
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35);
    c.drawCircle(Offset(cx, cy), r, paint);
    c.drawCircle(Offset(cx + r * 0.8, cy + r * 0.15), r * 0.72, paint);
    c.drawCircle(Offset(cx - r * 0.75, cy + r * 0.1), r * 0.68, paint);
    c.drawCircle(Offset(cx, cy + r * 0.3), r * 0.8, paint);
  }

  void _paintMote(Canvas c, Size size, double s, _Particle p, Color color) {
    final wob = _twoPi * (t + p.phase);
    final cx = (p.x + p.drift * math.sin(wob)) * size.width;
    final cy = (p.y + p.drift * 0.6 * math.cos(wob)) * size.height;
    final pulse = 0.5 + 0.5 * math.sin(_twoPi * (2 * t + p.phase));
    final a = (0.2 + 0.3 * pulse).clamp(0.0, 0.6);
    c.drawCircle(
      Offset(cx, cy),
      p.r * s,
      Paint()..color = color.withValues(alpha: a),
    );
  }

  void _paintFirefly(Canvas c, Size size, double s, _Particle p, Color color) {
    final wx = p.drift * math.sin(_twoPi * (t + p.phase));
    final wy = p.drift * 0.7 * math.cos(_twoPi * (t + p.phase * 1.3));
    final cx = (p.x + wx) * size.width;
    final cy = (p.y + wy) * size.height;
    final pulse = 0.5 + 0.5 * math.sin(_twoPi * (2 * t + p.phase));
    final a = (0.25 + 0.6 * pulse).clamp(0.0, 0.9);
    final r = p.r * s;
    c.drawCircle(
      Offset(cx, cy),
      r * 2.2,
      Paint()
        ..color = color.withValues(alpha: a * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.6),
    );
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = color.withValues(alpha: a),
    );
  }

  /// 昇る泡: t の 1 周で下外 → 上外へ 1 回上昇（seamless）。
  void _paintBubble(Canvas c, Size size, double s, _Particle p, Color color) {
    const margin = 0.15;
    final y01 = ((p.y - t) % 1.0 + 1.0) % 1.0;
    final cy = (y01 * (1 + 2 * margin) - margin) * size.height;
    final sway = 0.012 * math.sin(_twoPi * (2 * t + p.phase));
    final cx = (p.x + sway) * size.width;
    final r = p.r * s;
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, r * 0.12)
        ..color = color.withValues(alpha: 0.5),
    );
    c.drawCircle(
      Offset(cx - r * 0.35, cy - r * 0.35),
      r * 0.16,
      Paint()..color = color.withValues(alpha: 0.65),
    );
  }

  /// 降る雪: t の 1 周で上外 → 下外へ 1 回落下（seamless）+ 横揺れ。
  void _paintSnow(Canvas c, Size size, double s, _Particle p, Color color) {
    const margin = 0.1;
    final y01 = (p.y + t) % 1.0;
    final cy = (y01 * (1 + 2 * margin) - margin) * size.height;
    final sway = p.drift * math.sin(_twoPi * (2 * t + p.phase));
    final cx = (p.x + sway) * size.width;
    c.drawCircle(
      Offset(cx, cy),
      p.r * s,
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  void _paintTwinkle(Canvas c, Size size, double s, _Particle p, Color color) {
    final pulse = 0.5 + 0.5 * math.sin(_twoPi * (2 * t + p.phase));
    final a = (p.drift * (0.4 + 0.6 * pulse)).clamp(0.0, 1.0);
    final cx = p.x * size.width;
    final cy = p.y * size.height;
    final r = p.r * s;
    c.drawCircle(
      Offset(cx, cy),
      r * 1.8,
      Paint()
        ..color = color.withValues(alpha: a * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
    );
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = color.withValues(alpha: a),
    );
  }

  // t は毎フレーム変化する連続値のため、常に再描画が必要。
  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) => true;
}
