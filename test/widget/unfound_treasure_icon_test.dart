import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';

void main() {
  testWidgets('renders the SVG silhouette through a gray ShaderMask', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: UnfoundTreasureIcon(iconId: 'apple')),
        ),
      ),
    );

    // ShaderMask applies the gray gradient to the alpha silhouette.
    expect(find.byType(ShaderMask), findsOneWidget);

    // The silhouette uses the rich SVG art (same shape as the found state),
    // so the found <-> unfound reveal keeps a consistent outline.
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('gradient runs light (top) to dark (bottom) for contrast', () {
    const gradient = UnfoundTreasureIcon.grayGradient;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    // Bottom stop is darker and more opaque than the top stop, so the
    // silhouette stays visible even on bright backgrounds.
    final top = gradient.colors.first;
    final bottom = gradient.colors.last;
    expect(bottom.computeLuminance(), lessThan(top.computeLuminance()));
    expect(bottom.a, greaterThan(top.a));
  });
}
