import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/widgets/treasure_map_canvas.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

void main() {
  const size = Size(800, 600);

  test('trailNodeCenters returns one point per catalog scene, inside size', () {
    final pts = trailNodeCenters(size);

    expect(pts.length, kSceneCatalog.length);
    for (final p in pts) {
      expect(p.dx, inInclusiveRange(0, size.width));
      expect(p.dy, inInclusiveRange(0, size.height));
    }
  });

  test('trailNodeCenters maps normalized mapPos onto the given size', () {
    final pts = trailNodeCenters(size);
    final first = kSceneCatalog.first;

    expect(pts.first.dx, closeTo(first.mapPos.dx * size.width, 0.001));
    expect(pts.first.dy, closeTo(first.mapPos.dy * size.height, 0.001));
  });

  test('buildTrailPath produces a non-empty measurable path', () {
    final path = buildTrailPath(trailNodeCenters(size));

    expect(path.computeMetrics().isNotEmpty, isTrue);
  });

  test('buildTrailPath is empty for empty input', () {
    expect(buildTrailPath(const []).computeMetrics().isEmpty, isTrue);
  });

  test('legPath endpoints match the corresponding trail node centers', () {
    final pts = trailNodeCenters(size);
    final path = legPath(pts, 2);
    final metric = path.computeMetrics().first;

    final start = metric.getTangentForOffset(0)!.position;
    final end = metric.getTangentForOffset(metric.length)!.position;

    expect(start.dx, closeTo(pts[1].dx, 0.5));
    expect(start.dy, closeTo(pts[1].dy, 0.5));
    expect(end.dx, closeTo(pts[2].dx, 0.5));
    expect(end.dy, closeTo(pts[2].dy, 0.5));
  });

  test(
    'legPath returns an empty path for the first node (no incoming leg)',
    () {
      final pts = trailNodeCenters(size);

      expect(legPath(pts, 0).computeMetrics().isEmpty, isTrue);
    },
  );

  test('TrailPainter repaints only when cleared set changes', () {
    final a = TrailPainter(clearedIds: {'scene01'});
    final sameContent = TrailPainter(clearedIds: {'scene01'});
    final different = TrailPainter(clearedIds: {'scene01', 'scene02'});

    expect(a.shouldRepaint(sameContent), isFalse);
    expect(a.shouldRepaint(different), isTrue);
  });

  test('ParchmentPainter never repaints (fully static)', () {
    expect(
      const ParchmentPainter().shouldRepaint(const ParchmentPainter()),
      isFalse,
    );
  });
}
