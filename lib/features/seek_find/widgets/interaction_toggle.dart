import 'package:flutter/material.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_interaction.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/theme/kids_theme.dart';

/// 「うごかす（地図パン） / さがす（なぞって発見）」を切り替えるピル型トグル。
/// 大エリア（Normal/Hard）でのみ表示し、1 本指ドラッグの用途を明示的に選ばせる。
/// タップ発見はどちらのモードでも有効なので、これはドラッグの割り当てだけを変える。
class InteractionToggle extends StatelessWidget {
  const InteractionToggle({
    super.key,
    required this.interaction,
    required this.localeCode,
    required this.onChanged,
  });

  final SceneInteraction interaction;
  final String localeCode;
  final ValueChanged<SceneInteraction> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('interaction-toggle'),
      color: KidsTheme.toggleSurface,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InteractionChip(
              keyValue: 'interaction-move',
              icon: Icons.open_with,
              label: tr(localeCode, 'seek.move'),
              selected: interaction == SceneInteraction.move,
              onTap: () => onChanged(SceneInteraction.move),
            ),
            const SizedBox(width: 4),
            _InteractionChip(
              keyValue: 'interaction-trace',
              icon: Icons.gesture,
              label: tr(localeCode, 'seek.trace'),
              selected: interaction == SceneInteraction.trace,
              onTap: () => onChanged(SceneInteraction.trace),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionChip extends StatelessWidget {
  const _InteractionChip({
    required this.keyValue,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ホームの難易度トグル（_ModeChip）と同じ配色で見た目を統一する。
    final fg = selected ? Colors.white : Colors.brown.shade700;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: ValueKey(keyValue),
        onTap: onTap,
        child: Container(
          // タッチターゲット 60dp 以上（子供向け UX 基準）。
          constraints: const BoxConstraints(minWidth: 96, minHeight: 60),
          decoration: BoxDecoration(
            color: selected ? Colors.amber.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
