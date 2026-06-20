import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient.dart';

part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/forest_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/ocean_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/city_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/mountain_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/night_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/desert_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/space_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/undersea_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/snow_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/flower_field_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/rainbow_hills_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/castle_painter.dart';
part 'package:kidsapp_treasurehunt/features/seek_find/scene_background/galaxy_painter.dart';

/// シーン背景。静止画レイヤ（[_PaintedScene]）の上に環境アニメ層
/// （[sceneAmbient]）を重ねる。静止画はそのまま、その上で雲・光・雪などが緩く動く。
Widget sceneBackground(String sceneId) => Stack(
  fit: StackFit.expand,
  children: [_sceneBase(sceneId), sceneAmbient(sceneId)],
);

Widget _sceneBase(String sceneId) => switch (sceneId) {
  'scene01' => const _PaintedScene(painter: _ForestPainter()),
  'scene02' => const _PaintedScene(painter: _OceanPainter()),
  'scene03' => const _PaintedScene(painter: _CityPainter()),
  'scene04' => const _PaintedScene(painter: _MountainPainter()),
  'scene05' => const _PaintedScene(painter: _NightPainter()),
  'scene06' => const _PaintedScene(painter: _DesertPainter()),
  'scene07' => const _PaintedScene(painter: _SpacePainter()),
  'scene08' => const _PaintedScene(painter: _UnderseaPainter()),
  'scene09' => const _PaintedScene(painter: _SnowPainter()),
  'scene10' => const _PaintedScene(painter: _FlowerFieldPainter()),
  'scene11' => const _PaintedScene(painter: _RainbowHillsPainter()),
  'scene12' => const _PaintedScene(painter: _CastlePainter()),
  'scene13' => const _PaintedScene(painter: _GalaxyPainter()),
  _ => const ColoredBox(color: Color(0xFF87CEEB)),
};

class _PaintedScene extends StatelessWidget {
  const _PaintedScene({required this.painter});
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: painter, child: const SizedBox.expand());
}
