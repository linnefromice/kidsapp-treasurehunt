import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/data/settings_repository.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_shape.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrailShape', () {
    test('fromId maps known ids and falls back to circle', () {
      expect(TrailShape.fromId('circle'), TrailShape.circle);
      expect(TrailShape.fromId('star'), TrailShape.star);
      expect(TrailShape.fromId('comet'), TrailShape.comet);
      expect(TrailShape.fromId(null), TrailShape.circle);
      expect(TrailShape.fromId('???'), TrailShape.circle);
    });

    test('circle is always free; others unlock via a badge', () {
      expect(TrailShape.circle.unlockBadgeId, isNull);
      expect(TrailShape.star.unlockBadgeId, 'firstClear');
      expect(TrailShape.heart.unlockBadgeId, 'worldComplete');
      expect(TrailShape.bubble.unlockBadgeId, 'firstFind');
      expect(TrailShape.flower.unlockBadgeId, 'explorer');
      expect(TrailShape.neon.unlockBadgeId, 'hardAll');
      expect(TrailShape.ribbon.unlockBadgeId, 'normalAll');
      expect(TrailShape.comet.unlockBadgeId, 'rareAll');
    });

    test('ribbon and comet are stroke brushes; others are particles', () {
      expect(TrailShape.ribbon.isStroke, isTrue);
      expect(TrailShape.comet.isStroke, isTrue);
      for (final s in [
        TrailShape.circle,
        TrailShape.star,
        TrailShape.heart,
        TrailShape.bubble,
        TrailShape.flower,
        TrailShape.neon,
      ]) {
        expect(s.isStroke, isFalse, reason: '$s should be a particle');
      }
    });
  });

  group('SettingsRepository trailShape', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to circle and persists a selection', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      expect(repo.trailShapeId(), 'circle');
      await repo.setTrailShapeId('star');
      expect(repo.trailShapeId(), 'star');
      expect(TrailShape.fromId(repo.trailShapeId()), TrailShape.star);
    });
  });
}
