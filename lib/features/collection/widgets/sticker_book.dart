import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kidsapp_treasurehunt/data/collection_repository.dart';
import 'package:kidsapp_treasurehunt/features/collection/models/collection_world.dart';
import 'package:kidsapp_treasurehunt/features/collection/widgets/collection_cell.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// シール帳（D1）: ワールドを 1 ページ＝1 枚の「ページ」として横にめくる。
/// 下にページ位置ドット。ページめくりに触覚を添える。
class StickerBook extends StatefulWidget {
  const StickerBook({
    super.key,
    required this.worlds,
    required this.discovered,
    required this.unseen,
    required this.localeCode,
    required this.initialPage,
    required this.onPageChanged,
  });

  final List<CollectionWorld> worlds;
  final Set<String> discovered;
  final Set<String> unseen;
  final String localeCode;
  final int initialPage;
  final ValueChanged<int> onPageChanged;

  @override
  State<StickerBook> createState() => _StickerBookState();
}

class _StickerBookState extends State<StickerBook> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );
  late int _page = widget.initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const ValueKey('sticker-book'),
            controller: _controller,
            itemCount: widget.worlds.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick(); // めくる触覚
              widget.onPageChanged(i); // 親に現在ページを覚えさせる
              setState(() => _page = i);
            },
            itemBuilder: (context, i) => _WorldPage(
              world: widget.worlds[i],
              discovered: widget.discovered,
              unseen: widget.unseen,
              localeCode: widget.localeCode,
            ),
          ),
        ),
        _PageDots(count: widget.worlds.length, current: _page),
      ],
    );
  }
}

/// シール帳のページ位置ドット。
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    // 装飾（ページ位置）なので読み上げ対象から除外する。
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == current
                      ? Colors.brown.shade600
                      : Colors.brown.shade200,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// シール帳の 1 ページ（1 ワールド）。見出し（ワールド名 ＋ n/total）＋ 宝シール。
class _WorldPage extends StatelessWidget {
  const _WorldPage({
    required this.world,
    required this.discovered,
    required this.unseen,
    required this.localeCode,
  });

  final CollectionWorld world;
  final Set<String> discovered;
  final Set<String> unseen;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        key: ValueKey('collection-world.${world.sceneId}'),
        decoration: BoxDecoration(
          // 完成したワールドは羊皮紙が少し明るく、金枠＋やわらかい金グロー（#5）。
          color: complete ? const Color(0xFFFFFBEA) : const Color(0xFFFBF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: complete ? Colors.amber.shade400 : Colors.brown.shade200,
            width: complete ? 3.5 : 2,
          ),
          boxShadow: complete
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(localeCode, world.titleKey),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 完成は「コンプリート」チップ、途中は n/total 表示。
                if (complete)
                  Container(
                    key: ValueKey('collection-world-complete.${world.sceneId}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '🏆 ${tr(localeCode, 'collection.complete')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      '$foundCount/$total',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final iconId in world.iconIds)
                      CollectionCell(
                        sceneId: world.sceneId,
                        iconId: iconId,
                        discovered: discovered.contains(
                          CollectionRepository.entryKey(world.sceneId, iconId),
                        ),
                        isNew: unseen.contains(
                          CollectionRepository.entryKey(world.sceneId, iconId),
                        ),
                        localeCode: localeCode,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
