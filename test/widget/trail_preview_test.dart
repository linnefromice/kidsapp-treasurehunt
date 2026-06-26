import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsapp_treasurehunt/features/settings/widgets/trail_preview.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/trail_sparkle.dart';
import 'package:kidsapp_treasurehunt/providers.dart';

Future<void> _pumpPreview(WidgetTester tester, SharedPreferences prefs) async {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: TrailPreview())),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a hint until the child draws', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpPreview(tester, prefs);

    expect(find.text('ここで ためしがき'), findsOneWidget);
    expect(find.byType(TrailSparkle), findsNothing);
  });

  testWidgets('dragging spawns trail particles and hides the hint', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpPreview(tester, prefs);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('trail-preview'))),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(find.byType(TrailSparkle), findsWidgets);
    expect(find.text('ここで ためしがき'), findsNothing);

    await gesture.up();
    // 粒の自己消滅タイマー（800ms）＋アニメーションを消化して落ち着かせる。
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
