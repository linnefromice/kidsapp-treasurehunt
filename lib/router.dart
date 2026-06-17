import 'package:go_router/go_router.dart';

import 'features/seek_find/seek_find_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/treasure_map/treasure_map_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TreasureMapScreen()),
    GoRoute(
      path: '/hunt/:sceneId',
      builder: (context, state) =>
          SeekFindScreen(sceneId: state.pathParameters['sceneId']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
