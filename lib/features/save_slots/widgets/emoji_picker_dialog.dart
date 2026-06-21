import 'package:flutter/material.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// アバター絵文字を [kAvatarEmojis] から選ぶダイアログ。
/// 選んだ絵文字を `Navigator.pop` で返す（キャンセル時は null）。
///
/// 各セルは 60×60 dp 以上（kids UX のタッチターゲット基準）。
class EmojiPickerDialog extends StatelessWidget {
  const EmojiPickerDialog({super.key, required this.localeCode});

  final String localeCode;

  /// ダイアログを表示し、選ばれた絵文字（キャンセルは null）を返す。
  static Future<String?> show(BuildContext context, String localeCode) {
    return showDialog<String>(
      context: context,
      builder: (_) => EmojiPickerDialog(localeCode: localeCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('emoji-picker'),
      title: Text(tr(localeCode, 'slot.pick')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final emoji in kAvatarEmojis)
                _EmojiCell(
                  emoji: emoji,
                  onTap: () => Navigator.of(context).pop(emoji),
                ),
            ],
          ),
        ),
      ),
      // 幼児にはバリアタップでの閉じ方が分かりにくいので明示的な戻るボタンを置く。
      actions: [
        TextButton(
          key: const ValueKey('emoji-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(localeCode, 'slot.cancel')),
        ),
      ],
    );
  }
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(14));
    return Semantics(
      label: emoji,
      button: true,
      // 背景 + 枠線でボタンらしく見せ、セル同士の境目を明確にする。
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          key: ValueKey('emoji-pick.$emoji'),
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: scheme.outlineVariant, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 34)),
          ),
        ),
      ),
    );
  }
}
