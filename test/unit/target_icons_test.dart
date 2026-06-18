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
}
