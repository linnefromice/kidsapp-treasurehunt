import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/save_slots/widgets/emoji_picker_dialog.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/save_slots_catalog.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/widgets/parental_gate.dart';

class SlotSelectScreen extends ConsumerWidget {
  const SlotSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final created = ref.watch(saveSlotControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(localeCode, 'slot.title'))),
      body: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (final slot in kSaveSlots)
              _SlotCard(
                slot: slot,
                localeCode: localeCode,
                avatar: created[slot.id],
              ),
            _FreeModeCard(localeCode: localeCode),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({
    required this.slot,
    required this.localeCode,
    required this.avatar,
  });

  final SaveSlot slot;
  final String localeCode;

  /// 選択済みアバター絵文字。未作成（白紙）のスロットは null。
  final String? avatar;

  bool get isCreated => avatar != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        key: ValueKey('slot-card.${slot.id}'),
        onTap: () => _enter(context, ref),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Avatar(avatar: avatar, slotId: slot.id),
                  const SizedBox(height: 12),
                  Text(
                    isCreated
                        ? tr(localeCode, 'slot.continue')
                        : tr(localeCode, 'slot.new'),
                    key: ValueKey(
                      isCreated
                          ? 'slot-continue.${slot.id}'
                          : 'slot-new.${slot.id}',
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              if (isCreated)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    key: ValueKey('slot-reset.${slot.id}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _reset(context, ref),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enter(BuildContext context, WidgetRef ref) async {
    if (!isCreated) {
      // 白紙スロット: まずアバター絵文字を選ばせてから作成する。
      final emoji = await EmojiPickerDialog.show(context, localeCode);
      if (emoji == null || !context.mounted) return;
      await ref
          .read(saveSlotControllerProvider.notifier)
          .createSlot(slot.id, emoji);
    }
    if (!context.mounted) return;
    ref.read(activeSlotProvider.notifier).select(slot.id);
    context.go('/');
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await ParentalGate.show(context);
    if (ok) {
      await ref.read(saveSlotControllerProvider.notifier).resetSlot(slot.id);
    }
  }
}

/// スロットのアバター表示。作成済みは選んだ絵文字、白紙は破線枠＋「＋」。
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.slotId});

  final String? avatar;
  final String slotId;

  @override
  Widget build(BuildContext context) {
    final emoji = avatar;
    if (emoji != null) {
      return SizedBox(
        width: 88,
        height: 88,
        child: Center(
          child: Text(
            emoji,
            key: ValueKey('slot-avatar.$slotId'),
            style: const TextStyle(fontSize: 64),
          ),
        ),
      );
    }
    // 白紙プレースホルダ（固定アバターを出さない）。
    return Container(
      key: ValueKey('slot-empty.$slotId'),
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 3),
      ),
      child: Icon(Icons.add, size: 48, color: Colors.grey.shade400),
    );
  }
}

/// 全マップ解放モード（フリーモード）の入場カード。リセットや保護者ゲートは持たない。
class _FreeModeCard extends ConsumerWidget {
  const _FreeModeCard({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        key: const ValueKey('slot-card.free'),
        onTap: () => _enter(context, ref),
        child: SizedBox(
          width: 160,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 88, color: Colors.amber.shade700),
              const SizedBox(height: 12),
              Text(
                tr(localeCode, 'slot.free'),
                key: const ValueKey('slot-free'),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enter(BuildContext context, WidgetRef ref) async {
    await ref.read(saveSlotControllerProvider.notifier).enterFreeMode();
    if (!context.mounted) return;
    ref.read(activeSlotProvider.notifier).select(kFreeModeSlotId);
    context.go('/');
  }
}
