import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';

void main() {
  test('returns mapped icon for known ids, fallback for unknown', () {
    expect(targetIcon('apple'), Icons.apple);
    expect(targetIcon('duck'), Icons.flutter_dash);
    expect(targetIcon('star'), Icons.star);
    expect(targetIcon('mystery'), Icons.help_outline);
  });

  test('returns icons for scene02/03 targets', () {
    expect(targetIcon('ball'), Icons.sports_soccer);
    expect(targetIcon('flower'), Icons.local_florist);
    expect(targetIcon('heart'), Icons.favorite);
  });

  test('targetColor returns distinct color for each known id', () {
    expect(targetColor('apple'), const Color(0xFFE53935));
    expect(targetColor('duck'), const Color(0xFFFDD835));
    expect(targetColor('star'), const Color(0xFFFB8C00));
    expect(targetColor('leaf'), const Color(0xFF43A047));
    expect(targetColor('key'), const Color(0xFFFFB300));
  });

  test('targetColor falls back to grey for unknown id', () {
    expect(targetColor('nonexistent'), const Color(0xFF9E9E9E));
  });
}
