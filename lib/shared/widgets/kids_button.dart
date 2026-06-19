import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/shared/theme/kids_theme.dart';

/// 子供向けの大きな立体ボタン。暗い底面の上に明るい面が浮いた厚みのある見た目で、
/// 押すと面が底面に沈み込む。子供でも「押せる」と視覚的に分かる。最小 60x60 を保証。
class KidsButton extends StatefulWidget {
  const KidsButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<KidsButton> createState() => _KidsButtonState();
}

class _KidsButtonState extends State<KidsButton> {
  static const double _radius = 24;
  static const double _depth = 6; // 立体の厚み(dp)
  static const Duration _pressDuration = Duration(milliseconds: 70);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = scheme.primary;
    // 底面（厚みの影）は面より暗い同系色。
    final base = Color.alphaBlend(Colors.black.withValues(alpha: 0.28), face);
    final radius = BorderRadius.circular(_radius);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          widget.onPressed();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: KidsTheme.minTouchTarget,
            minHeight: KidsTheme.minTouchTarget,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: base,
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            // 面を底面の上に厚みぶん浮かせる。押すと上下の余白を入れ替えて沈ませる。
            child: AnimatedPadding(
              duration: _pressDuration,
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                top: _pressed ? _depth : 0,
                bottom: _pressed ? 0 : _depth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // 上を明るくしてツヤ＝立体感を出す。
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.22),
                        face,
                      ),
                      face,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimary,
                        // ツヤのグラデで明るくなる上部でも読めるよう軽い影で担保。
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
