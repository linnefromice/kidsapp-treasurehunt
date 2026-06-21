import 'package:flutter_test/flutter_test.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/models/scene_interaction.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

void main() {
  group('dragBehaviorFor', () {
    test('Easy always traces and never pans (画面ぴったり)', () {
      // Easy はトグル非表示。interaction に関わらず常になぞり・パン無し。
      for (final i in SceneInteraction.values) {
        final b = dragBehaviorFor(GameMode.easy, i);
        expect(b.traceEnabled, isTrue);
        expect(b.panEnabled, isFalse);
      }
    });

    test('Normal move-mode pans and does not trace', () {
      final b = dragBehaviorFor(GameMode.normal, SceneInteraction.move);
      expect(b.panEnabled, isTrue);
      expect(b.traceEnabled, isFalse);
    });

    test('Normal trace-mode traces and does not pan', () {
      final b = dragBehaviorFor(GameMode.normal, SceneInteraction.trace);
      expect(b.panEnabled, isFalse);
      expect(b.traceEnabled, isTrue);
    });

    test('Hard behaves like Normal for drag assignment', () {
      expect(
        dragBehaviorFor(GameMode.hard, SceneInteraction.move).panEnabled,
        isTrue,
      );
      expect(
        dragBehaviorFor(GameMode.hard, SceneInteraction.trace).traceEnabled,
        isTrue,
      );
    });

    test('pan and trace are never both enabled (no conflict)', () {
      // バッティング不在の不変条件: ドラッグの割り当ては常に排他。
      for (final m in GameMode.values) {
        for (final i in SceneInteraction.values) {
          final b = dragBehaviorFor(m, i);
          expect(
            b.panEnabled && b.traceEnabled,
            isFalse,
            reason: 'mode=$m interaction=$i must not enable both',
          );
        }
      }
    });
  });
}
