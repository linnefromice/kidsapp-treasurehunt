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
}
