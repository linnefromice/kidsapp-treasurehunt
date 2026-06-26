import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kidsapp_treasurehunt/features/badges/models/badge.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';

/// 称号バッチのギャラリー（図鑑の第3タブ「しょうごう」）。
/// 取得済み=カラー＋名前＋説明、未取得=グレーのシルエット＋「？」。
/// あつめるコレクションとして見せる（競争・順位は出さない）。
class BadgeGallery extends StatelessWidget {
  const BadgeGallery({
    super.key,
    required this.earned,
    required this.unseen,
    required this.localeCode,
  });

  final Set<String> earned;
  final Set<String> unseen;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('badge-gallery'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final b in kBadgeCatalog)
          _BadgeTile(
            def: b,
            earned: earned.contains(b.id),
            isNew: unseen.contains(b.id),
            localeCode: localeCode,
          ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.def,
    required this.earned,
    required this.isNew,
    required this.localeCode,
  });

  final BadgeDef def;
  final bool earned;
  final bool isNew;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('badge.${def.id}'),
      color: earned ? Colors.amber.shade50 : null,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: earned
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(badgeSvgAsset(def.iconId)),
                        if (isNew)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: _NewBadge(localeCode: localeCode),
                          ),
                      ],
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix(_greyscale),
                      child: Opacity(
                        opacity: 0.5,
                        child: SvgPicture.asset(badgeSvgAsset(def.iconId)),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earned ? tr(localeCode, def.labelKey) : '？？？',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(localeCode, def.descKey),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「NEW」ラベル（小）。
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        tr(localeCode, 'collection.new'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// グレースケール化（未取得バッジのシルエット用）。輝度で R=G=B にする。
const List<double> _greyscale = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];
