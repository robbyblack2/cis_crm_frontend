import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/theme/app_theme.dart';
import 'package:cis_crm/core/theme/theme_cubit.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        BlocProvider<WebSocketCubit>.value(value: getIt<WebSocketCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr is AuthAuthenticated && prev is! AuthAuthenticated,
            listener: (context, state) {
              context.read<WebSocketCubit>().connect();
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr is AuthUnauthenticated && prev is! AuthUnauthenticated,
            listener: (context, state) {
              context.read<WebSocketCubit>().disconnect();
            },
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)?.appTitle ?? 'CIS CRM',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: getIt<GoRouter>(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
  }
}
