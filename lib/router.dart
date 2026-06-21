import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kidsapp_treasurehunt/features/collection/collection_screen.dart';
import 'package:kidsapp_treasurehunt/features/save_slots/slot_select_screen.dart';
import 'package:kidsapp_treasurehunt/features/seek_find/seek_find_screen.dart';
import 'package:kidsapp_treasurehunt/features/settings/settings_screen.dart';
import 'package:kidsapp_treasurehunt/features/treasure_map/treasure_map_screen.dart';
import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/shared/game_mode.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/slots',
    redirect: (context, state) {
      final hasSlot = ref.read(activeSlotProvider) != null;
      final atSlots = state.matchedLocation == '/slots';
      if (!hasSlot && !atSlots) return '/slots';
      return null;
    },
    routes: [
      GoRoute(
        path: '/slots',
        builder: (context, state) => const SlotSelectScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const TreasureMapScreen(),
      ),
      GoRoute(
        path: '/hunt/:sceneId',
        builder: (context, state) => SeekFindScreen(
          sceneId: state.pathParameters['sceneId']!,
          mode: gameModeFromQuery(state.uri.queryParameters['mode']),
        ),
      ),
      GoRoute(
        path: '/collection',
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
