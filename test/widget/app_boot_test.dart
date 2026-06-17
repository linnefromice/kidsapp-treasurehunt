import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/app.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

void main() {
  testWidgets('boots to the treasure map home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.unlockedSceneIds': ['scene01'],
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TreasureHuntApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('たからの ちず'), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-card.scene01')), findsOneWidget);
  });
}
