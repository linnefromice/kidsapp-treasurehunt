import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

/// Normal / Hard（探索エリアが画面より広いモード）でのドラッグの割り当て。
/// 「マップのずらし」と「なぞり発見（ペン）」のバッティングを避けるため、
/// 子どもが明示的に切り替える（[move]＝地図を動かす / [trace]＝なぞって探す）。
///
/// タップ発見はどちらのモードでも常に有効なので、この enum はあくまで
/// 「1 本指ドラッグを何に使うか」だけを決める。
enum SceneInteraction { move, trace }

/// 1 本指ドラッグの割り当て。[panEnabled] と [traceEnabled] は排他で、
/// 同時に true にはならない（= パンとなぞりがバッティングしない不変条件）。
class DragBehavior {
  const DragBehavior({required this.panEnabled, required this.traceEnabled});

  /// InteractiveViewer の 1 本指パンを許可するか。
  final bool panEnabled;

  /// GestureDetector の onPan で「なぞって発見」を行うか。
  final bool traceEnabled;
}

/// [mode] と（大エリア時の）[interaction] から 1 本指ドラッグの割り当てを決める。
///
/// - [GameMode.easy]: シーンが画面ぴったりでパン不要。常になぞり（トグル非表示）。
/// - [GameMode.normal] / [GameMode.hard]:
///   - [SceneInteraction.move]: ドラッグ＝地図パン（なぞりは無効）。
///   - [SceneInteraction.trace]: ドラッグ＝なぞって発見（パンは無効）。
DragBehavior dragBehaviorFor(GameMode mode, SceneInteraction interaction) {
  if (mode == GameMode.easy) {
    return const DragBehavior(panEnabled: false, traceEnabled: true);
  }
  return switch (interaction) {
    SceneInteraction.move => const DragBehavior(
      panEnabled: true,
      traceEnabled: false,
    ),
    SceneInteraction.trace => const DragBehavior(
      panEnabled: false,
      traceEnabled: true,
    ),
  };
}
