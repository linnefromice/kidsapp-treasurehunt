import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/trail_sparkle.dart';

Widget _host(Widget child) {
  // TrailSparkle は Positioned を返すため Stack の直下に置く必要がある。
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(children: [child]),
  );
}

void main() {
  testWidgets('renders, fades out, and disposes cleanly', (tester) async {
    await tester.pumpWidget(
      _host(
        const TrailSparkle(
          key: ValueKey('sparkle'),
          position: Offset(40, 40),
          color: Color(0xFF42A5F5),
        ),
      ),
    );

    // 生成直後は透明から始まり（フェードイン）、少し進めると見える。
    expect(find.byKey(const ValueKey('sparkle')), findsOneWidget);
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    await tester.pump(const Duration(milliseconds: 100));
    expect(fade.opacity.value, greaterThan(0.0));

    // アニメーション(計500ms)を最後まで進めると透明に戻る。
    await tester.pump(const Duration(milliseconds: 400));
    expect(fade.opacity.value, closeTo(0.0, 0.001));

    // ウィジェットを外しても例外（AnimationController リーク等）が出ない。
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not intercept pointer events', (tester) async {
    await tester.pumpWidget(
      _host(
        const TrailSparkle(position: Offset(10, 10), color: Color(0xFFFFFFFF)),
      ),
    );

    // 純粋な装飾なのでポインタを奪わない（IgnorePointer 配下）。
    expect(find.byType(IgnorePointer), findsOneWidget);
  });
}
