import 'package:flutter/widgets.dart';

/// タブレット横向きを第一級にするための簡易ブレークポイント。
class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tablet;
}
