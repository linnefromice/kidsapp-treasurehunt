import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/lives_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int lives,
  required int max,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LivesBar(lives: lives, max: max),
      ),
    ),
  );
}

void main() {
  testWidgets('full lives show all filled hearts, none empty', (tester) async {
    await _pump(tester, lives: 3, max: 3);
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('losing lives shows filled + outline hearts summing to max', (
    tester,
  ) async {
    await _pump(tester, lives: 1, max: 3);
    expect(find.byIcon(Icons.favorite), findsNWidgets(1));
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
  });

  testWidgets('zero lives shows all outline hearts', (tester) async {
    await _pump(tester, lives: 0, max: 3);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(3));
  });
}
