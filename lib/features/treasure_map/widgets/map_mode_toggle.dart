import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/shared/game_mode.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/theme/kids_theme.dart';

/// 「やさしい / ふつう / むずかしい / ぷろ」を切り替えるピル型トグル。常時表示。
class MapModeToggle extends StatelessWidget {
  const MapModeToggle({
    super.key,
    required this.mode,
    required this.localeCode,
    required this.onChanged,
  });

  final GameMode mode;
  final String localeCode;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('map-mode-toggle'),
      color: KidsTheme.toggleSurface,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeChip(
              keyValue: 'mode-easy',
              label: tr(localeCode, 'home.modeEasy'),
              selected: mode == GameMode.easy,
              onTap: () => onChanged(GameMode.easy),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              keyValue: 'mode-normal',
              label: tr(localeCode, 'home.modeNormal'),
              selected: mode == GameMode.normal,
              onTap: () => onChanged(GameMode.normal),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              keyValue: 'mode-hard',
              label: '🔥 ${tr(localeCode, 'home.modeHard')}',
              selected: mode == GameMode.hard,
              onTap: () => onChanged(GameMode.hard),
            ),
            const SizedBox(width: 4),
            _ModeChip(
              keyValue: 'mode-pro',
              label: '⭐ ${tr(localeCode, 'home.modePro')}',
              selected: mode == GameMode.pro,
              onTap: () => onChanged(GameMode.pro),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.keyValue,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String keyValue;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: ValueKey(keyValue),
        onTap: onTap,
        child: Container(
          // タッチターゲット 60dp 以上を確保（子供向け UX 基準）。
          constraints: const BoxConstraints(minWidth: 96, minHeight: 60),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.amber.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.brown.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
