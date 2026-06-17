import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('shows a card per scene; first unlocked, others locked', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.slot1.unlockedSceneIds': ['scene01'],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(activeSlotProvider.notifier).select('slot1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TreasureMapScreen()),
      ),
    );

    expect(find.byKey(const ValueKey('scene-card.scene01')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-card.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('locked.scene02')), findsOneWidget);
    expect(find.byKey(const ValueKey('locked.scene01')), findsNothing);
  });
}
