import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/collection_bar.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/treasure_glyph.dart';

const _kRect = Rect.fromLTWH(0, 0, 0.1, 0.1);

FindTarget _target(String id, {String? iconId}) => FindTarget(
  id: id,
  iconId: iconId ?? id,
  labelKey: id,
  normalizedRect: _kRect,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<FindTarget> targets,
  required Set<String> foundIds,
  EdgeInsets systemPadding = EdgeInsets.zero,
}) {
  // SafeArea は MediaQuery.paddingOf(context)（= padding）を消費するため、
  // ここで padding を与えれば SafeArea がそのぶん中身を inset する。
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(padding: systemPadding),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CollectionBar(targets: targets, foundIds: foundIds),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one slot per icon group and marks completed ones', (
    tester,
  ) async {
    await _pump(
      tester,
      targets: [_target('apple'), _target('duck'), _target('star')],
      foundIds: const {'apple'},
    );

    expect(find.byKey(const ValueKey('slot.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.star')), findsOneWidget);
    // apple is fully found -> lit; duck is not -> grey.
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('unfound.duck')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.duck')), findsNothing);
  });

  testWidgets('shows target glyphs (grey when unfound, lit when found)', (
    tester,
  ) async {
    await _pump(
      tester,
      targets: [_target('apple'), _target('duck')],
      foundIds: const {'apple'},
    );

    // Unfound duck -> grey silhouette glyph; found apple -> full-colour glyph.
    final duck = tester.widget<TreasureGlyph>(
      find.byKey(const ValueKey('unfound.duck')),
    );
    expect(duck.iconId, 'duck');
    expect(duck.found, isFalse);
    final apple = tester.widget<TreasureGlyph>(
      find.byKey(const ValueKey('found.apple')),
    );
    expect(apple.iconId, 'apple');
    expect(apple.found, isTrue);
  });

  testWidgets('groups duplicate icons into one slot with a count-up badge', (
    tester,
  ) async {
    // heart_1 and heart_2 share iconId="heart" -> a single "heart" slot.
    await _pump(
      tester,
      targets: [
        _target('apple'),
        _target('heart_1', iconId: 'heart'),
        _target('heart_2', iconId: 'heart'),
      ],
      foundIds: const {'heart_1'},
    );

    // One slot for the icon, not one per target id.
    expect(find.byKey(const ValueKey('slot.heart')), findsOneWidget);
    expect(find.byKey(const ValueKey('slot.heart_1')), findsNothing);
    expect(find.byKey(const ValueKey('slot.heart_2')), findsNothing);

    // 1 of 2 found -> badge counts up, slot stays unlit until complete.
    expect(find.byKey(const ValueKey('count.heart')), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('unfound.heart')), findsOneWidget);
    expect(find.byKey(const ValueKey('found.heart')), findsNothing);

    // Single-count groups get no badge.
    expect(find.byKey(const ValueKey('count.apple')), findsNothing);
  });

  testWidgets('keeps slots clear of the bottom system inset (SafeArea)', (
    tester,
  ) async {
    const bottomInset = 80.0;
    await _pump(
      tester,
      targets: [_target('apple')],
      foundIds: const {},
      systemPadding: const EdgeInsets.only(bottom: bottomInset),
    );

    final screenBottom = tester.getSize(find.byType(MaterialApp)).height;
    final slotBottom = tester
        .getRect(find.byKey(const ValueKey('slot.apple')))
        .bottom;
    // The slot must sit above the system navigation inset, not under it.
    expect(slotBottom, lessThanOrEqualTo(screenBottom - bottomInset));
  });

  testWidgets('lights the grouped slot and shows a check when all are found', (
    tester,
  ) async {
    await _pump(
      tester,
      targets: [
        _target('heart_1', iconId: 'heart'),
        _target('heart_2', iconId: 'heart'),
      ],
      foundIds: const {'heart_1', 'heart_2'},
    );

    expect(find.byKey(const ValueKey('found.heart')), findsOneWidget);
    expect(find.byKey(const ValueKey('unfound.heart')), findsNothing);
    // Completed badge swaps the fraction for a language-independent check.
    expect(find.byKey(const ValueKey('count.heart')), findsOneWidget);
    expect(find.text('2/2'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('count.heart')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
