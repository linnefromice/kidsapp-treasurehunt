import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 宝探しの一時停止メニュー。戻る操作（AppBar の戻る・システムバック）の
/// 誤タップで即ホームに飛ばないよう、いったんここで受け止める。
///
/// `Navigator.pop` の戻り値で意思を返す: true=ちずに もどる / false（or 外タップ）
/// =つづける。失敗を罰しない方針に沿い、既定（外タップ）は安全側の「つづける」。
class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_filled,
              size: 56,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              tr(localeCode, 'pause.title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _PauseButton(
              key: const ValueKey('pause-resume'),
              icon: Icons.play_arrow_rounded,
              label: tr(localeCode, 'pause.resume'),
              color: Colors.amber.shade600,
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 12),
            _PauseButton(
              key: const ValueKey('pause-toMap'),
              icon: Icons.map_rounded,
              label: tr(localeCode, 'seek.toMap'),
              color: Colors.brown.shade400,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// 大きめ（60dp 以上）のキッズ向けボタン。絵＋ラベルで読字に頼り切らない。
class _PauseButton extends StatelessWidget {
  const _PauseButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, minHeight: 60),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
