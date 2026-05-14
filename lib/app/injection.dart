import 'package:cis_crm/core/analytics/analytics_service.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:cis_crm/core/flags/feature_flag_service.dart';
import 'package:cis_crm/core/logging/app_logger.dart';
import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/dio_client.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/core/observability/app_bloc_observer.dart';
import 'package:cis_crm/core/router/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(FlavorConfig config) async {
  // ── 1. Config + leaves ──────────────────────────────────────────
  getIt.registerSingleton<FlavorConfig>(config);
  // ignore: cascade_invocations
  getIt.registerLazySingleton<AppLogger>(
    () => AppLogger(level: config.logLevel),
  );

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ignore: cascade_invocations
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ── 2. Network providers ────────────────────────────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(getIt<FlutterSecureStorage>()),
  );
  // ignore: cascade_invocations
  getIt.registerLazySingleton<AuthApi>(
    () => AuthApi(Dio(), baseUrl: config.apiBaseUrl),
  );
  // ignore: cascade_invocations
  getIt.registerLazySingleton<Dio>(
    () => createDioClient(
      config: config,
      logger: getIt<AppLogger>(),
      tokens: getIt<TokenStorage>(),
      authApi: getIt<AuthApi>(),
    ),
  );

  // ── 3. Cross-cutting services (no-op defaults) ──────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<AnalyticsService>(
    () => const NoopAnalyticsService(),
  );
  // ignore: cascade_invocations
  getIt.registerLazySingleton<FeatureFlagService>(
    () => const NoopFeatureFlagService(),
  );

  // ── 4. Bloc observer ────────────────────────────────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<AppBlocObserver>(
    () => AppBlocObserver(getIt<AppLogger>()),
  );

  // ── 5. Data sources ─────────────────────────────────────────────

  // ── 6. Repositories ─────────────────────────────────────────────

  // ── 7. App-wide blocs ───────────────────────────────────────────

  // ── 8. Router ──────────────────────────────────────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<GoRouter>(
    () => GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('CIS CRM Home')),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login')),
          ),
        ),
      ],
    ),
  );
}
