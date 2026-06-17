import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kidsapp_treasurehunt/providers.dart';
import 'package:kidsapp_treasurehunt/router.dart';
import 'package:kidsapp_treasurehunt/shared/strings/strings.dart';
import 'package:kidsapp_treasurehunt/shared/theme/kids_theme.dart';

class TreasureHuntApp extends ConsumerWidget {
  const TreasureHuntApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: tr(locale.languageCode, 'app.title'),
      theme: KidsTheme.light(),
      locale: locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
