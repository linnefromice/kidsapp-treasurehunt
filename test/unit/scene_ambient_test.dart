import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient.dart';

void main() {
  const sceneIds = [
    'scene01',
    'scene02',
    'scene03',
    'scene04',
    'scene05',
    'scene06',
    'scene07',
    'scene08',
    'scene09',
  ];

  test('every catalog scene has at least one ambient spec', () {
    for (final id in sceneIds) {
      expect(
        ambientSpecsFor(id),
        isNotEmpty,
        reason: '$id should have ambient animation',
      );
    }
  });

  test('unknown scene id returns no ambient specs', () {
    expect(ambientSpecsFor('does-not-exist'), isEmpty);
  });

  test('each scene stays within the particle budget', () {
    for (final id in sceneIds) {
      final total = ambientSpecsFor(
        id,
      ).fold<int>(0, (sum, spec) => sum + spec.count);
      expect(
        total,
        lessThanOrEqualTo(kAmbientMaxParticlesPerScene),
        reason: '$id exceeds the ambient particle budget',
      );
    }
  });

  test('scene kinds match their environment', () {
    expect(
      ambientSpecsFor('scene08').map((s) => s.kind),
      contains(AmbientKind.bubble),
    );
    expect(
      ambientSpecsFor('scene09').map((s) => s.kind),
      contains(AmbientKind.snow),
    );
    expect(
      ambientSpecsFor('scene03').map((s) => s.kind),
      contains(AmbientKind.twinkle),
    );
    expect(
      ambientSpecsFor('scene05').map((s) => s.kind),
      contains(AmbientKind.firefly),
    );
    expect(
      ambientSpecsFor('scene01').map((s) => s.kind),
      contains(AmbientKind.drift),
    );
  });

  test('all spec counts are positive', () {
    for (final id in sceneIds) {
      for (final spec in ambientSpecsFor(id)) {
        expect(spec.count, greaterThan(0), reason: '$id has a zero-count spec');
      }
    }
  });
}
