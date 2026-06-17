import 'package:flutter/material.dart';

/// 保護者ゲートの入口 stub。MVP では確認ダイアログのみ(算数問題は後続spec)。
class ParentalGate {
  const ParentalGate._();

  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('おとなのひと へ'),
        content: const Text('このさきは おとなのひと と いっしょに。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('もどる'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
