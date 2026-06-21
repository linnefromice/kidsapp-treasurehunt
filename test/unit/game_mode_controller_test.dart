import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults to easy when nothing persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await _container();
    expect(c.read(gameModeControllerProvider), GameMode.easy);
  });

  test('initial state reads the persisted mode (survives a restart)', () async {
    SharedPreferences.setMockInitialValues({'settings.gameMode': 'hard'});
    final c = await _container();
    expect(c.read(gameModeControllerProvider), GameMode.hard);
  });

  test('select updates state and persists for the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await _container();
    await c.read(gameModeControllerProvider.notifier).select(GameMode.normal);

    expect(c.read(gameModeControllerProvider), GameMode.normal);
    // 新しいコンテナ（= 次回起動相当）でも保持されている。
    final c2 = await _container();
    expect(c2.read(gameModeControllerProvider), GameMode.normal);
  });
}
