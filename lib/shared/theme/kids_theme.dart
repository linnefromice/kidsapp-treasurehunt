import 'package:flutter/material.dart';

/// 子供向けの明るく丸いテーマ。
class KidsTheme {
  const KidsTheme._();

  /// 子供向け最小タッチターゲット(dp)。
  static const double minTouchTarget = 60;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFA000),
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
  }
}
