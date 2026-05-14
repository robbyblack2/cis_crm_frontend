import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics_service.dart';
import '../core/env/flavor_config.dart';
import '../core/flags/feature_flag_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/auth_api.dart';
import '../core/network/dio_client.dart';
import '../core/network/token_storage.dart';
import '../core/observability/app_bloc_observer.dart';
// Add when wiring auth feature + router:
// import 'package:go_router/go_router.dart';
// import '../core/router/app_router.dart';

// import '../features/auth/data/datasources/auth_remote_data_source.dart';
// import '../features/auth/data/repositories/auth_repository_impl.dart';
// import '../features/auth/domain/repositories/auth_repository.dart';
// import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Global service locator. Resolve dependencies anywhere via `getIt<T>()`.
final GetIt getIt = GetIt.instance;

/// Builds the dependency graph in bottom-up order.
///
/// Called once from [main.dart] after `HydratedBloc.storage` is set and
/// before `runApp`. Layering:
///   1. Config + leaves (FlavorConfig, AppLogger, SharedPreferences,
///      secure storage).
///   2. Network providers (Dio + token storage + raw refresh API).
///   3. Cross-cutting services (Analytics, FeatureFlags — no-op defaults).
///   4. Bloc observer (depends on AppLogger).
///   5. Data sources.
///   6. Repositories (registered against abstract interfaces).
///   7. App-wide blocs (singletons).
///   8. GoRouter (depends on the auth repository's status stream).
Future<void> configureDependencies(FlavorConfig config) async {
  // ── 1. Config + leaves ──────────────────────────────────────────
  getIt.registerSingleton<FlavorConfig>(config);
  getIt.registerLazySingleton<AppLogger>(
    () => AppLogger(level: config.logLevel),
  );

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ── 2. Network providers ────────────────────────────────────────
  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<AuthApi>(
    () => AuthApi(Dio(), baseUrl: config.apiBaseUrl),
  );
  getIt.registerLazySingleton<Dio>(
    () => createDioClient(
      config: config,
      logger: getIt<AppLogger>(),
      tokens: getIt<TokenStorage>(),
      authApi: getIt<AuthApi>(),
    ),
  );

  // ── 3. Cross-cutting services (no-op defaults) ──────────────────
  getIt.registerLazySingleton<AnalyticsService>(
    () => const NoopAnalyticsService(),
  );
  getIt.registerLazySingleton<FeatureFlagService>(
    () => const NoopFeatureFlagService(),
  );

  // ── 4. Bloc observer ────────────────────────────────────────────
  getIt.registerLazySingleton<AppBlocObserver>(
    () => AppBlocObserver(getIt<AppLogger>()),
  );

  // ── 5. Data sources ─────────────────────────────────────────────
  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  // );

  // ── 6. Repositories ─────────────────────────────────────────────
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remote: getIt<AuthRemoteDataSource>(),
  //     tokens: getIt<TokenStorage>(),
  //   ),
  // );

  // ── 7. App-wide blocs ───────────────────────────────────────────
  // getIt.registerLazySingleton<AuthBloc>(
  //   () => AuthBloc(getIt<AuthRepository>()),
  // );

  // ── 8. Router ──────────────────────────────────────────────────
  // The router subscribes to AuthRepository.status (NOT AuthBloc.stream)
  // so the cold-start redirect runs against the repository.
  // getIt.registerLazySingleton<GoRouter>(
  //   () => buildAppRouter(
  //     authStatusStream: getIt<AuthRepository>().status,
  //     navigatorKey: appNavigatorKey,
  //     redirect: ...,                  // force-upgrade → onboarding → auth
  //     routes: [...],
  //   ),
  // );
}
