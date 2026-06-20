import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/seek_find/models/trail_color.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final localeController = ref.read(localeControllerProvider.notifier);
    final trailColor = ref.watch(trailColorControllerProvider);
    final trailColorController = ref.read(
      trailColorControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(tr(localeCode, 'settings.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(localeCode, 'settings.language'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                key: const ValueKey('lang.ja'),
                label: const Text('にほんご'),
                selected: localeCode == 'ja',
                onSelected: (_) => localeController.setLocale('ja'),
              ),
              ChoiceChip(
                key: const ValueKey('lang.en'),
                label: const Text('English'),
                selected: localeCode == 'en',
                onSelected: (_) => localeController.setLocale('en'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            tr(localeCode, 'settings.trailColor'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final choice in TrailColorChoice.values)
                _TrailColorChip(
                  choice: choice,
                  label: tr(localeCode, 'trailColor.${choice.id}'),
                  selected: trailColor == choice,
                  onSelected: () => trailColorController.select(choice),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// なぞりトレイル色の選択チップ。スウォッチ + ラベルで読字に依存しない。
///
/// 6 つの同型チップを共通化したもの（component-reuse の 3 つ以上ルール）。
class _TrailColorChip extends StatelessWidget {
  const _TrailColorChip({
    required this.choice,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final TrailColorChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    // キッズ UX 基準: 最小 60x60 dp のタップターゲットを保証する。
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
      child: ChoiceChip(
        key: ValueKey('trailColor.${choice.id}'),
        // しろ等の淡色がチップ背景に埋もれないよう薄いフチを付ける。
        avatar: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: choice.baseColor,
            border: Border.all(color: Colors.black26),
          ),
        ),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
