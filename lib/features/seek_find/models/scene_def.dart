import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/rare_treasure.dart';

/// 1シーンの定義(背景 + 隠し宝のリスト)。
class SceneDef {
  const SceneDef({
    required this.id,
    required this.titleKey,
    required this.imageAsset,
    required this.targets,
    this.dummies = const [],
    this.hardDummies = const [],
  });

  final String id;
  final String titleKey;
  final String imageAsset;
  final List<FindTarget> targets;
  final List<DummyItem> dummies;

  /// ハードモード専用の引っかけダミー（通常モードでは描画されない）。
  /// JSON の任意フィールド `hardDummies`。未指定なら空。
  final List<DummyItem> hardDummies;

  factory SceneDef.fromJson(Map<String, dynamic> json) {
    return SceneDef(
      id: json['id'] as String,
      titleKey: json['titleKey'] as String,
      imageAsset: json['imageAsset'] as String,
      targets: (json['targets'] as List<dynamic>)
          .map((e) => FindTarget.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      dummies: json.containsKey('dummies')
          ? (json['dummies'] as List<dynamic>)
                .map((e) => DummyItem.fromJson(e as Map<String, dynamic>))
                .toList(growable: false)
          : const [],
      hardDummies: json.containsKey('hardDummies')
          ? (json['hardDummies'] as List<dynamic>)
                .map((e) => DummyItem.fromJson(e as Map<String, dynamic>))
                .toList(growable: false)
          : const [],
    );
  }

  static Future<SceneDef> loadAsset(String sceneId) async {
    final raw = await rootBundle.loadString('assets/scenes/$sceneId.json');
    return SceneDef.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// 全アイテム（宝・ダミー・ハードダミー）の**中心座標を入れ替えた**新しい
  /// [SceneDef] を返す（C1 配置シャッフル）。id・iconId・labelKey・サイズ・scale は
  /// すべて保持し、位置だけを置き換える。
  ///
  /// クリア済みシーンの再訪やフリーモードで「毎回ちがう場所」を作り、no-time /
  /// no-fail のままリプレイ性を上げる（アセット追加ゼロ）。中心は元の集合の置換
  /// なので、元が重ならない配置なら入れ替えても重ならない（数・難度は不変）。
  SceneDef withShuffledPositions(Random random) {
    final centers = <Offset>[
      for (final t in targets) t.normalizedRect.center,
      for (final d in dummies) d.normalizedRect.center,
      for (final d in hardDummies) d.normalizedRect.center,
    ]..shuffle(random);

    var i = 0;
    Rect place(Rect original) {
      final c = centers[i++];
      return Rect.fromCenter(
        center: c,
        width: original.width,
        height: original.height,
      );
    }

    // 中心の取り出しと同じ順（targets → dummies → hardDummies）で割り当てる。
    final newTargets = [
      for (final t in targets)
        FindTarget(
          id: t.id,
          iconId: t.iconId,
          labelKey: t.labelKey,
          normalizedRect: place(t.normalizedRect),
        ),
    ];
    final newDummies = [
      for (final d in dummies)
        DummyItem(
          id: d.id,
          iconId: d.iconId,
          normalizedRect: place(d.normalizedRect),
          scale: d.scale,
        ),
    ];
    final newHardDummies = [
      for (final d in hardDummies)
        DummyItem(
          id: d.id,
          iconId: d.iconId,
          normalizedRect: place(d.normalizedRect),
          scale: d.scale,
        ),
    ];

    return SceneDef(
      id: id,
      titleKey: titleKey,
      imageAsset: imageAsset,
      targets: newTargets,
      dummies: newDummies,
      hardDummies: newHardDummies,
    );
  }

  /// 低頻度レア宝（C4）を 1 つ足した新しい [SceneDef] を返す。
  ///
  /// おとり（[dummies]）が 1 つでもあれば、そのうち 1 つの**位置を借りて**レア宝
  /// （ターゲット）に置き換える。これにより配置は必ず非重複（既存の升を再利用）で、
  /// レアは「出れば必ず見つけられる」（no-fail）。おとりが無ければ何もしない。
  /// 図鑑 100% 判定はベースカタログのみなので、レアは運に左右される必須要素には
  /// ならない（ボーナス）。
  SceneDef withRareTreasure(RareTreasure rare, Random random) {
    if (dummies.isEmpty) {
      return this;
    }
    final borrow = random.nextInt(dummies.length);
    final slot = dummies[borrow];
    final rareTarget = FindTarget(
      id: rare.iconId, // base のターゲット id（apple_1 等）と衝突しない
      iconId: rare.iconId,
      labelKey: rare.labelKey,
      normalizedRect: slot.normalizedRect,
    );
    return SceneDef(
      id: id,
      titleKey: titleKey,
      imageAsset: imageAsset,
      targets: [...targets, rareTarget],
      dummies: [
        for (var i = 0; i < dummies.length; i++)
          if (i != borrow) dummies[i],
      ],
      hardDummies: hardDummies,
    );
  }
}
