import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

const _kRect = Rect.fromLTWH(0, 0, 0.1, 0.1);

FindTarget _target(String id, {String? iconId}) => FindTarget(
  id: id,
  iconId: iconId ?? id,
  labelKey: id,
  normalizedRect: _kRect,
);

void main() {
  testWidgets('renders one slot per target and marks found ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollectionBar(
            targets: [_target('apple'), _target('duck'), _target('star')],
            foundIds: const {'apple'},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('slot.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.duck')), findsNothing);
  });

  testWidgets('shows target icons (grey when unfound, lit when found)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollectionBar(
            targets: [_target('apple'), _target('duck')],
            foundIds: const {'apple'},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('unfound.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);

    final duck = tester.widget<Icon>(
      find.byKey(const ValueKey('unfound.duck')),
    );
    expect(duck.icon, targetIcon('duck'));
    final apple = tester.widget<Icon>(
      find.byKey(const ValueKey('found.apple')),
    );
    expect(apple.icon, targetIcon('apple'));
  });

  testWidgets('uses iconId for icon when it differs from id', (tester) async {
    // heart_1 and heart_2 share iconId="heart"
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CollectionBar(
            targets: [
              _target('heart_1', iconId: 'heart'),
              _target('heart_2', iconId: 'heart'),
            ],
            foundIds: const {'heart_1'},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('slot.heart_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.heart_2')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.heart_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unfound.heart_2')), findsOneWidget);

    final heart1Icon = tester.widget<Icon>(
      find.byKey(const ValueKey('found.heart_1')),
    );
    final heart2Icon = tester.widget<Icon>(
      find.byKey(const ValueKey('unfound.heart_2')),
    );
    // Both use the same icon because they share iconId
    expect(heart1Icon.icon, targetIcon('heart'));
    expect(heart2Icon.icon, targetIcon('heart'));
  });
}
