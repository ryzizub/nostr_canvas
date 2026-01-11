import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:nostr_place/app/router.dart';
import 'package:nostr_place/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Nostr Place',
      theme: flutterNesTheme(brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
