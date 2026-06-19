import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/hint_glow.dart';

void main() {
  testWidgets('plays a one-shot glow pulse without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HintGlow(color: Colors.teal)),
      ),
    );
    expect(find.byType(HintGlow), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposes its controller cleanly when removed from the tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HintGlow(color: Colors.teal)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    // hinting が false に戻った状況を再現: ツリーから取り除く。
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(HintGlow), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
