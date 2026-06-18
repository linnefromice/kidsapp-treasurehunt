import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:kidsapp_treasurehunt/features/seek_find/models/dummy_item.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/find_target.dart';

/// 1シーンの定義(背景 + 隠し宝のリスト)。
class SceneDef {
  const SceneDef({
    required this.id,
    required this.titleKey,
    required this.imageAsset,
    required this.targets,
    this.dummies = const [],
  });

  final String id;
  final String titleKey;
  final String imageAsset;
  final List<FindTarget> targets;
  final List<DummyItem> dummies;

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
    );
  }

  static Future<SceneDef> loadAsset(String sceneId) async {
    final raw = await rootBundle.loadString('assets/scenes/$sceneId.json');
    return SceneDef.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
