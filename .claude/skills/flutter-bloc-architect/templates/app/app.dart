import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
// import '../l10n/generated/app_localizations.dart';
import 'injection.dart';

/// Root widget.
///
/// Hosts only **app-wide** blocs as singletons — feature-scoped blocs are
/// provided at page level via `BlocProvider(create: (_) => getIt<XxxBloc>())`.
///
/// `MultiBlocListener` at the App root is the canonical place for
/// cross-feature reactions (per official BLoC guidance: no bloc imports
/// another bloc). Examples wired here:
///   - On `AuthUnauthenticated` → dispatch `XxxCleared` events to every
///     user-scoped bloc (cart, drafts, recent searches, …).
///   - On `ConnectivityStatus.offline` → show banner.
///   - On push payload received → navigate via `appNavigatorKey`.
///
/// `appNavigatorKey` lets non-widget code (auth interceptor, push handler,
/// localization escape-hatch) reach the navigator without a bloc.
final appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        // BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        // BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          // BlocListener<AuthBloc, AuthState>(
          //   listenWhen: (prev, curr) =>
          //       curr is AuthUnauthenticated && prev is! AuthUnauthenticated,
          //   listener: (context, _) {
          //     // dispatch XxxCleared to user-scoped blocs:
          //     // context.read<CartBloc>().add(const CartCleared());
          //   },
          // ),
        ],
        child: MaterialApp.router(
          title: 'My Flutter App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: getIt<GoRouter>(),
          localizationsDelegates: const [
            // AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          // supportedLocales: AppLocalizations.supportedLocales,
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
  }
}
