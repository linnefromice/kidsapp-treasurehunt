import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/found_burst.dart';

void main() {
  testWidgets('animates a found marker without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FoundBurst(color: Colors.teal)),
      ),
    );
    expect(find.byType(FoundBurst), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders a high-intensity (grand finale) burst without throwing',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: FoundBurst(color: Colors.teal, intensity: 2.0)),
          ),
        ),
      );
      expect(find.byType(FoundBurst), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    },
  );
}
