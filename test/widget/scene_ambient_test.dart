import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/scene_background.dart';

Future<void> _pumpScene(WidgetTester tester, String sceneId) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: sceneBackground(sceneId))),
  );
  // 環境アニメは無限ループのため pumpAndSettle は使えない。pump のみ。
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('animated scene renders an AmbientLayer without error', (
    tester,
  ) async {
    await _pumpScene(tester, 'scene01');

    expect(find.byType(AmbientLayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all nine scenes render with an ambient layer', (tester) async {
    for (var i = 1; i <= 9; i++) {
      final id = 'scene${i.toString().padLeft(2, '0')}';
      await _pumpScene(tester, id);

      expect(
        find.byType(AmbientLayer),
        findsOneWidget,
        reason: '$id should host an ambient layer',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '$id threw while painting',
      );
    }
  });

  testWidgets('unknown scene renders without an ambient layer or error', (
    tester,
  ) async {
    await _pumpScene(tester, 'no-such-scene');

    expect(find.byType(AmbientLayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposes its animation controller cleanly on removal', (
    tester,
  ) async {
    await _pumpScene(tester, 'scene09');
    expect(find.byType(AmbientLayer), findsOneWidget);

    // 層を外して dispose を走らせ、ticker リーク等の例外が出ないことを確認。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AmbientLayer), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
