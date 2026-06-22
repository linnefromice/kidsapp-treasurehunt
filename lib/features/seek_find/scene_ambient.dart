/// シーン背景に重ねる「生きた背景」アニメ層。
///
/// 既存の静止画 painter（`scene_background.dart`）には一切触れず、その上に
/// 低振幅・緩ループの環境アニメ（漂う雲・舞う光・ホタル・昇る泡・降る雪・星の瞬き）を
/// 重ねる。1 本の [AnimationController] が `t`(0..1) を回し、全粒子が共有する。
/// `RepaintBoundary` で静止画層と分離するため、静止画は再描画されない。
///
/// SDK のみ（`CustomPainter` + `dart:ui`）・アセット不要・追加 package 不要。
///
/// このファイルは公開エントリ（barrel）。実体は 2 つに分割されている:
/// - `scene_ambient/ambient_spec.dart` … 種類・設定・シーン別の決定論的 spec 表
/// - `scene_ambient/ambient_layer.dart` … 共有ティッカー駆動の描画層と painter
library;

export 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient/ambient_layer.dart';
export 'package:kidsapp_treasurehunt/features/seek_find/scene_ambient/ambient_spec.dart';
