import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';

void main() {
  testWidgets('renders the icon silhouette through a gray ShaderMask', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: UnfoundTreasureIcon(iconId: 'apple')),
        ),
      ),
    );

    // ShaderMask applies the gradient to the icon's alpha silhouette.
    expect(find.byType(ShaderMask), findsOneWidget);

    // The underlying icon matches the treasure's icon id.
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, targetIcon('apple'));
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
