import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';

void main() {
  testWidgets('renders one slot per target and marks found ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CollectionBar(
            targetIds: ['apple', 'duck', 'star'],
            foundIds: {'apple'},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('slot.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.duck')), findsNothing);
  });
}
