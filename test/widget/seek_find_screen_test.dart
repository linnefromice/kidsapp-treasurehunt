import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/audio/audio_service.dart';

// scene01.json の target 正規化中心(left+width/2, top+height/2)。シーンローカル座標へは ×kSceneSize。
const _sceneCenters = {
  'apple': Offset((0.10 + 0.07) * 800, (0.15 + 0.09) * 600),
  'duck': Offset((0.60 + 0.07) * 800, (0.30 + 0.09) * 600),
  'star': Offset((0.40 + 0.07) * 800, (0.68 + 0.09) * 600),
};

Future<ProviderContainer> _pumpScene(WidgetTester tester) async {
  // シーン(800x600)が AppBar/図鑑の下に丸ごと収まるよう、テスト面を広げる。
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioServiceProvider.overrideWithValue(SilentAudioService()),
    ],
  );
  addTearDown(container.dispose);

  // rootBundle.loadString は flutter_test の擬似イベントループでは 2 番目以降の
  // テストで解決しない既知の制約があるため、実イベントループ(runAsync)で
  // FutureProvider のシーンロードを先に解決させてから widget を pump する。
  await tester.runAsync(() => container.read(sceneProvider('scene01').future));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SeekFindScreen(sceneId: 'scene01')),
    ),
  );
  // FutureProvider(scene load)の解決を待つ
  await tester.pumpAndSettle();
  return container;
}

/// シーン要素の画面上の原点を基準に、目的のターゲット中心をグローバル座標へ変換してタップ。
Future<void> _tapTarget(WidgetTester tester, String id) async {
  final origin = tester.getTopLeft(find.byKey(const ValueKey('scene-content')));
  await tester.tapAt(origin + _sceneCenters[id]!);
  await tester.pump();
}

void main() {
  testWidgets('tapping a target fills its collection slot', (tester) async {
    await _pumpScene(tester);

    expect(find.byKey(const ValueKey('found.apple')), findsNothing);
    await _tapTarget(tester, 'apple');
    expect(find.byKey(const ValueKey('found.apple')), findsOneWidget);
  });

  testWidgets('finding all targets marks the scene cleared', (tester) async {
    final container = await _pumpScene(tester);

    for (final id in _sceneCenters.keys) {
      await _tapTarget(tester, id);
    }
    await tester.pumpAndSettle();

    final progress = container.read(progressRepositoryProvider);
    expect(progress.isCleared('scene01'), isTrue);
    expect(find.text('みつけたね！'), findsOneWidget);
  });
}
