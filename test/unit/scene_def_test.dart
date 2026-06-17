import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_def.dart';

void main() {
  test('SceneDef.fromJson parses targets into normalized rects', () {
    final scene = SceneDef.fromJson(const {
      'id': 'scene01',
      'titleKey': 'scene.scene01.title',
      'imageAsset': 'assets/scenes/scene01.png',
      'targets': [
        {
          'id': 'apple',
          'labelKey': 'target.apple',
          'left': 0.1,
          'top': 0.2,
          'width': 0.3,
          'height': 0.4,
        },
      ],
    });

    expect(scene.id, 'scene01');
    expect(scene.targets, hasLength(1));
    final FindTarget t = scene.targets.single;
    expect(t.id, 'apple');
    expect(t.normalizedRect, const Rect.fromLTWH(0.1, 0.2, 0.3, 0.4));
  });
}
