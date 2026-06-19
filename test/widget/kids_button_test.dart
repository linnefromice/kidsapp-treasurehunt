import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/kids_button.dart';

void main() {
  testWidgets('is at least 60x60 and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KidsButton(label: 'GO', onPressed: () => tapped = true),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(KidsButton));
    expect(size.width, greaterThanOrEqualTo(60));
    expect(size.height, greaterThanOrEqualTo(60));

    await tester.tap(find.byType(KidsButton));
    expect(tapped, isTrue);
  });

  testWidgets('sinks on press-down and fires once on release', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KidsButton(label: 'GO', onPressed: () => taps++),
          ),
        ),
      ),
    );

    // Press-and-hold should animate the sink without firing yet.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(KidsButton)),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(taps, 0);
    expect(tester.takeException(), isNull);

    // Releasing fires onPressed exactly once.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
