import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/scenes_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads one entry per playable scene with distinct target icons',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final worlds = await container.read(collectionCatalogProvider.future);

      final playable = kSceneCatalog.where((e) => e.hasScene).length;
      expect(worlds, hasLength(playable));

      final scene01 = worlds.firstWhere((w) => w.sceneId == 'scene01');
      // scene01（森）の宝はテーマ別の 5 種（重複なし・登場順）。
      expect(scene01.iconIds.toSet(), {
        'mushroom',
        'acorn',
        'fox',
        'owl',
        'butterfly',
      });
      // 重複は畳まれている（distinct）。
      expect(scene01.iconIds.toSet().length, scene01.iconIds.length);
    },
  );
}
