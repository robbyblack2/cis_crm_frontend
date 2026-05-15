import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/theme/app_theme.dart';
import 'package:cis_crm/core/theme/theme_cubit.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr is AuthUnauthenticated && prev is! AuthUnauthenticated,
            listener: (context, state) {
              // TODO(auth): Dispatch XxxCleared to user-scoped blocs as
              // they are added.
            },
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'CIS CRM',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: getIt<GoRouter>(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en')],
            );
          },
        ),
      ),
    );
  }
}
