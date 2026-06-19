import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/save_slots/widgets/emoji_picker_dialog.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';

/// ピッカーを開き、戻り値を後から検証できるようにラッチへ格納する。
Future<String? Function()> _openPicker(WidgetTester tester) async {
  String? picked;
  var done = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await EmojiPickerDialog.show(context, 'ja');
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => done ? picked : null;
}

void main() {
  testWidgets('renders a cell for every whitelisted emoji', (tester) async {
    await _openPicker(tester);

    expect(find.byKey(const ValueKey('emoji-picker')), findsOneWidget);
    for (final emoji in kAvatarEmojis) {
      expect(
        find.byKey(ValueKey('emoji-pick.$emoji')),
        findsOneWidget,
        reason: '$emoji cell should exist',
      );
    }
  });

  testWidgets('tapping an emoji returns it to the caller', (tester) async {
    final result = await _openPicker(tester);

    await tester.tap(find.byKey(const ValueKey('emoji-pick.🦊')));
    await tester.pumpAndSettle();

    expect(result(), '🦊');
    expect(find.byKey(const ValueKey('emoji-picker')), findsNothing);
  });

  testWidgets('dismissing via the barrier returns null', (tester) async {
    final result = await _openPicker(tester);

    // ダイアログ外（バリア）をタップして閉じる。
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result(), isNull);
    expect(find.byKey(const ValueKey('emoji-picker')), findsNothing);
  });
}
