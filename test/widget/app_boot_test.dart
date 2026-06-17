import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('boots to the slot select screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TreasureHuntApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('slot-card.slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot-new.slot1')), findsOneWidget);
  });
}
