import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/target_icons.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/widgets/unfound_treasure_icon.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 図鑑（コレクション）画面。ワールドごとに、そのシーンの宝アイコンを
/// **未収集=影絵（グレーのシルエット）/ 収集=カラー** で並べる（D6）。
/// 「集めた宝の絵そのものがご褒美」になり、進捗が「絵の完成」で直感的に分かる。
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(localeControllerProvider).languageCode;
    // スロット未選択（通常は router redirect で /slots に飛ぶ）の防御。
    // collectionRepositoryProvider は slot null で throw するため、先にガードする。
    final activeSlot = ref.watch(activeSlotProvider);
    if (activeSlot == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final catalogAsync = ref.watch(collectionCatalogProvider);
    // discovered() はビルド毎に prefs を読む。図鑑は /collection への新規入場で
    // 都度ビルドされ、その時点の最新の収集状況を読む（発見は別画面=/hunt で起き、
    // record がキャッシュを同期更新済みなので、再入場で必ず反映される）。
    final discovered = ref.watch(collectionRepositoryProvider).discovered();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(tr(localeCode, 'collection.title')),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
        data: (worlds) => ListView(
          key: const ValueKey('collection-list'),
          padding: const EdgeInsets.all(16),
          children: [
            for (final world in worlds)
              _WorldSection(
                world: world,
                discovered: discovered,
                localeCode: localeCode,
              ),
          ],
        ),
      ),
    );
  }
}

/// 1 ワールド分のカード。見出し（ワールド名 ＋ n/total）＋ 宝セルの折り返し。
class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.world,
    required this.discovered,
    required this.localeCode,
  });

  final CollectionWorld world;
  final Set<String> discovered;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final foundCount = world.iconIds
        .where(
          (ic) => discovered.contains(
            CollectionRepository.entryKey(world.sceneId, ic),
          ),
        )
        .length;
    final total = world.iconIds.length;
    final complete = total > 0 && foundCount >= total;

    return Card(
      key: ValueKey('collection-world.${world.sceneId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(localeCode, world.titleKey),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$foundCount/$total ${complete ? '🏆' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final iconId in world.iconIds)
                  _CollectionCell(
                    sceneId: world.sceneId,
                    iconId: iconId,
                    discovered: discovered.contains(
                      CollectionRepository.entryKey(world.sceneId, iconId),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 宝 1 つのセル。収集済みはカラー、未収集は影絵（[UnfoundTreasureIcon]）。
class _CollectionCell extends StatelessWidget {
  const _CollectionCell({
    required this.sceneId,
    required this.iconId,
    required this.discovered,
  });

  final String sceneId;
  final String iconId;
  final bool discovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('collection-cell.$sceneId.$iconId'),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: discovered ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.brown.shade300, width: 2),
      ),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: FittedBox(
            fit: BoxFit.contain,
            child: discovered
                ? Icon(
                    targetIcon(iconId),
                    color: targetColor(iconId),
                    key: ValueKey('collection-found.$sceneId.$iconId'),
                  )
                : UnfoundTreasureIcon(
                    key: ValueKey('collection-silhouette.$sceneId.$iconId'),
                    iconId: iconId,
                  ),
          ),
        ),
      ),
    );
  }
}
