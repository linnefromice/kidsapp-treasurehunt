import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_shape.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/trail_sparkle.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 設定の「ためしがき」キャンバス（#3）。選んだ色＋ブラシで実際になぞって試せる。
/// 宝探し画面と同じ描画（粒 or ストローク）を使い、コスメの違いを手で確かめられる。
class TrailPreview extends ConsumerStatefulWidget {
  const TrailPreview({super.key});

  @override
  ConsumerState<TrailPreview> createState() => _TrailPreviewState();
}

class _TrailPreviewState extends ConsumerState<TrailPreview> {
  static const double _height = 120;
  static const double _minDist = 14;
  static const int _maxPoints = 30;

  final List<({Offset position, Key key, Color color})> _points = [];
  Offset? _lastSpawn;
  int _seq = 0;

  void _spawn(Offset pos) {
    final last = _lastSpawn;
    if (last != null && (pos - last).distance < _minDist) return;
    _lastSpawn = pos;
    final setting = ref.read(trailSettingControllerProvider);
    final color = resolveTrailColor(setting, particleIndex: _seq);
    _seq++;
    final key = UniqueKey();
    setState(() {
      _points.add((position: pos, key: key, color: color));
      if (_points.length > _maxPoints) _points.removeAt(0);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _points.removeWhere((p) => p.key == key));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final shape = ref.watch(trailShapeControllerProvider);
    return GestureDetector(
      key: const ValueKey('trail-preview'),
      behavior: HitTestBehavior.opaque,
      onPanDown: (d) {
        _lastSpawn = null;
        _seq = 0;
        _spawn(d.localPosition);
      },
      onPanUpdate: (d) => _spawn(d.localPosition),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: _height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.brown.shade200, width: 2),
          ),
          child: Stack(
            children: [
              if (_points.isEmpty)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.brown.shade300,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(localeCode, 'settings.trailTry'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              if (shape.isStroke)
                Positioned.fill(
                  child: TrailStroke(
                    points: [
                      for (final p in _points)
                        (position: p.position, color: p.color),
                    ],
                    comet: shape == TrailShape.comet,
                  ),
                )
              else ...[
                for (final p in _points)
                  TrailSparkle(
                    key: p.key,
                    position: p.position,
                    color: p.color,
                    shape: shape,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
