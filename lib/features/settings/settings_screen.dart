import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 設定画面。言語など端末ぜんたいの設定を扱う。
/// なぞりペンのカスタマイズは独立した「ペン」画面（`/pen`）に分離した。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    final localeController = ref.read(localeControllerProvider.notifier);

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
        ],
      ),
    );
  }
}
