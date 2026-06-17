import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../scenes_catalog.dart';
import '../../shared/strings/strings.dart';

class TreasureMapScreen extends ConsumerWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressRepositoryProvider);
    final localeCode = ref.watch(localeControllerProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(localeCode, 'home.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final entry in kSceneCatalog)
            _SceneCard(
              entry: entry,
              localeCode: localeCode,
              unlocked: progress.isUnlocked(entry.id),
              cleared: progress.isCleared(entry.id),
              onTap: progress.isUnlocked(entry.id)
                  ? () => context.go('/hunt/${entry.id}')
                  : null,
            ),
        ],
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.entry,
    required this.localeCode,
    required this.unlocked,
    required this.cleared,
    required this.onTap,
  });

  final SceneCatalogEntry entry;
  final String localeCode;
  final bool unlocked;
  final bool cleared;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('scene-card.${entry.id}'),
      onTap: onTap,
      child: Card(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                tr(localeCode, entry.titleKey),
                textAlign: TextAlign.center,
              ),
            ),
            if (!unlocked)
              Icon(Icons.lock, key: ValueKey('locked.${entry.id}'), size: 40),
            if (cleared)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
