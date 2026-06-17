import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// 子供向けの大きな丸ボタン。最小 60x60 を保証する。
class KidsButton extends StatelessWidget {
  const KidsButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: KidsTheme.minTouchTarget,
        minHeight: KidsTheme.minTouchTarget,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
