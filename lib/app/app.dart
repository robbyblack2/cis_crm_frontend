import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider + MultiBlocListener will wrap this widget once
    // app-wide blocs are registered. Until then, render the router directly.
    // See SKILL.md "Cross-feature reactions" for the canonical pattern.
    return MaterialApp.router(
      title: 'CIS CRM',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: getIt<GoRouter>(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
