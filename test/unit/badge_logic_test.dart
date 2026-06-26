import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/badges/badge_logic.dart';
import 'package:kidsapp_treasurehunt/features/badges/models/badge.dart';

void main() {
  test('empty inputs earn no badges', () {
    expect(evaluateBadges(BadgeInputs.empty), isEmpty);
  });

  test('each fact unlocks exactly its badge (no cross-talk)', () {
    expect(evaluateBadges(_only(anyDiscovered: true)), {
      BadgeKind.firstFind.name,
    });
    expect(evaluateBadges(_only(anyCleared: true)), {
      BadgeKind.firstClear.name,
    });
    expect(evaluateBadges(_only(anyWorldComplete: true)), {
      BadgeKind.worldComplete.name,
    });
    expect(evaluateBadges(_only(easyAllCleared: true)), {
      BadgeKind.easyAll.name,
    });
    expect(evaluateBadges(_only(normalAllCleared: true)), {
      BadgeKind.normalAll.name,
    });
    expect(evaluateBadges(_only(hardAllCleared: true)), {
      BadgeKind.hardAll.name,
    });
    expect(evaluateBadges(_only(collectionComplete: true)), {
      BadgeKind.collectionComplete.name,
    });
    expect(evaluateBadges(_only(rareFoundCount: 1)), {
      BadgeKind.rareFirst.name,
    });
    expect(evaluateBadges(_only(rareAllFound: true, rareFoundCount: 3)), {
      BadgeKind.rareFirst.name,
      BadgeKind.rareAll.name,
    });
    expect(evaluateBadges(_only(allWorldsVisited: true)), {
      BadgeKind.explorer.name,
    });
  });

  test('rareFirst needs at least one rare; zero earns nothing', () {
    expect(evaluateBadges(_only(rareFoundCount: 0)), isEmpty);
  });

  test('evaluate is idempotent for the same inputs', () {
    final i = _only(anyCleared: true, easyAllCleared: true);
    expect(evaluateBadges(i), evaluateBadges(i));
  });

  test('every badge id maps back to a catalog entry', () {
    final all = evaluateBadges(
      const BadgeInputs(
        anyDiscovered: true,
        anyCleared: true,
        anyWorldComplete: true,
        easyAllCleared: true,
        normalAllCleared: true,
        hardAllCleared: true,
        collectionComplete: true,
        rareFoundCount: 3,
        rareAllFound: true,
        allWorldsVisited: true,
      ),
    );
    expect(all.length, kBadgeCatalog.length);
    for (final id in all) {
      expect(kBadgeById.containsKey(id), isTrue);
    }
  });
}

BadgeInputs _only({
  bool anyDiscovered = false,
  bool anyCleared = false,
  bool anyWorldComplete = false,
  bool easyAllCleared = false,
  bool normalAllCleared = false,
  bool hardAllCleared = false,
  bool collectionComplete = false,
  int rareFoundCount = 0,
  bool rareAllFound = false,
  bool allWorldsVisited = false,
}) => BadgeInputs(
  anyDiscovered: anyDiscovered,
  anyCleared: anyCleared,
  anyWorldComplete: anyWorldComplete,
  easyAllCleared: easyAllCleared,
  normalAllCleared: normalAllCleared,
  hardAllCleared: hardAllCleared,
  collectionComplete: collectionComplete,
  rareFoundCount: rareFoundCount,
  rareAllFound: rareAllFound,
  allWorldsVisited: allWorldsVisited,
);
