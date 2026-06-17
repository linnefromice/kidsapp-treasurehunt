import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'shared/strings/strings.dart';
import 'shared/theme/kids_theme.dart';

class TreasureHuntApp extends ConsumerWidget {
  const TreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: tr(locale.languageCode, 'app.title'),
      theme: KidsTheme.light(),
      locale: locale,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
