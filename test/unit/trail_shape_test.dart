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
      expect(TrailShape.fromId('heart'), TrailShape.heart);
      expect(TrailShape.fromId(null), TrailShape.circle);
      expect(TrailShape.fromId('???'), TrailShape.circle);
    });

    test('circle is always free; star/heart unlock via a badge', () {
      expect(TrailShape.circle.unlockBadgeId, isNull);
      expect(TrailShape.star.unlockBadgeId, 'firstClear');
      expect(TrailShape.heart.unlockBadgeId, 'worldComplete');
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
