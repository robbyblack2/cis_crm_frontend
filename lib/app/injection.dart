import 'package:cis_crm/app/app.dart';
import 'package:cis_crm/core/analytics/analytics_service.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:cis_crm/core/flags/feature_flag_service.dart';
import 'package:cis_crm/core/logging/app_logger.dart';
import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/dio_client.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/core/observability/app_bloc_observer.dart';
import 'package:cis_crm/core/router/app_router.dart';
import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/call_log_repository_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/task_repository_impl.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cis_crm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cis_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cis_crm/features/auth/presentation/pages/login_page.dart';
import 'package:cis_crm/features/automation/data/datasources/automation_remote_data_source.dart';
import 'package:cis_crm/features/automation/data/repositories/automation_repository_impl.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:cis_crm/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cis_crm/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/repositories/company_repository_impl.dart';
import 'package:cis_crm/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/email/data/repositories/email_repository_impl.dart';
import 'package:cis_crm/features/email/domain/repositories/email_repository.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
import 'package:cis_crm/features/files/data/datasources/file_remote_datasource.dart';
import 'package:cis_crm/features/files/data/repositories/file_repository_impl.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_cubit.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/datasources/record_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/repositories/pipeline_repository_impl.dart';
import 'package:cis_crm/features/pipeline/data/repositories/record_repository_impl.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/pipeline_repository.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/products/data/repositories/product_repository_impl.dart';
import 'package:cis_crm/features/products/data/repositories/subscription_repository_impl.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';
import 'package:cis_crm/features/products/domain/repositories/subscription_repository.dart';
import 'package:cis_crm/features/products/presentation/bloc/products_bloc.dart';
import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:cis_crm/features/reporting/domain/repositories/report_repository.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:cis_crm/features/search/data/repositories/search_repository_impl.dart';
import 'package:cis_crm/features/search/domain/repositories/search_repository.dart';
import 'package:cis_crm/features/search/presentation/bloc/search_bloc.dart';
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
  final dio = getIt<Dio>();

  // ignore: cascade_invocations
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio),
    )
    ..registerLazySingleton<ContactRemoteDataSource>(
      () => ContactRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<CompanyRemoteDataSource>(
      () => CompanyRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<PipelineRemoteDataSource>(
      () => PipelineRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<RecordRemoteDataSource>(
      () => RecordRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<CalendarRemoteDataSource>(
      () => CalendarRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<ActivityRemoteDataSource>(
      () => ActivityRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<AutomationRemoteDataSource>(
      () => AutomationRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<ProductRemoteDatasource>(
      () => ProductRemoteDatasourceImpl(dio: dio),
    )
    ..registerLazySingleton<SubscriptionRemoteDatasource>(
      () => SubscriptionRemoteDatasourceImpl(dio: dio),
    )
    ..registerLazySingleton<EmailRemoteDataSource>(
      () => EmailRemoteDataSourceImpl(dio: dio),
    )
    ..registerLazySingleton<FileRemoteDatasource>(
      () => FileRemoteDatasourceImpl(dio: dio),
    )
    ..registerLazySingleton<SearchRemoteDatasource>(
      () => SearchRemoteDatasourceImpl(dio: dio),
    )
    ..registerLazySingleton<ReportRemoteDataSource>(
      () => ReportRemoteDataSourceImpl(dio: dio),
    );

  // ── 6. Repositories ─────────────────────────────────────────────
  // ignore: cascade_invocations
  getIt
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: getIt<AuthRemoteDataSource>(),
        tokenStorage: getIt<TokenStorage>(),
      ),
    )
    ..registerLazySingleton<ContactRepository>(
      () => ContactRepositoryImpl(
        remoteDataSource: getIt<ContactRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<CompanyRepository>(
      () => CompanyRepositoryImpl(
        remoteDataSource: getIt<CompanyRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<PipelineRepository>(
      () => PipelineRepositoryImpl(
        remoteDataSource: getIt<PipelineRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<RecordRepository>(
      () => RecordRepositoryImpl(
        remoteDataSource: getIt<RecordRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<CalendarRepository>(
      () => CalendarRepositoryImpl(
        remoteDataSource: getIt<CalendarRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(
        remoteDataSource: getIt<ActivityRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<CallLogRepository>(
      () => CallLogRepositoryImpl(
        remoteDataSource: getIt<ActivityRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<AutomationRepository>(
      () => AutomationRepositoryImpl(
        remoteDataSource: getIt<AutomationRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        datasource: getIt<ProductRemoteDatasource>(),
      ),
    )
    ..registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(
        datasource: getIt<SubscriptionRemoteDatasource>(),
      ),
    )
    ..registerLazySingleton<EmailRepository>(
      () => EmailRepositoryImpl(
        remoteDataSource: getIt<EmailRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<FileRepository>(
      () => FileRepositoryImpl(
        datasource: getIt<FileRemoteDatasource>(),
      ),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(
        datasource: getIt<SearchRemoteDatasource>(),
      ),
    )
    ..registerLazySingleton<ReportRepository>(
      () => ReportRepositoryImpl(
        dataSource: getIt<ReportRemoteDataSource>(),
      ),
    );

  // ── 7. App-wide blocs (singletons) ─────────────────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  // ── 8. Feature blocs (factories — fresh per page mount) ────────
  // ignore: cascade_invocations
  getIt
    ..registerFactory<ContactsBloc>(
      () => ContactsBloc(
        contactRepository: getIt<ContactRepository>(),
      ),
    )
    ..registerFactory<PipelineBloc>(
      () => PipelineBloc(
        pipelineRepository: getIt<PipelineRepository>(),
      ),
    )
    ..registerFactory<RecordBloc>(
      () => RecordBloc(
        recordRepository: getIt<RecordRepository>(),
      ),
    )
    ..registerFactory<CalendarBloc>(
      () => CalendarBloc(repository: getIt<CalendarRepository>()),
    )
    ..registerFactory<TasksBloc>(
      () => TasksBloc(taskRepository: getIt<TaskRepository>()),
    )
    ..registerFactory<CallLogCubit>(
      () => CallLogCubit(
        callLogRepository: getIt<CallLogRepository>(),
      ),
    )
    ..registerFactory<AutomationBloc>(
      () => AutomationBloc(
        repository: getIt<AutomationRepository>(),
      ),
    )
    ..registerFactory<ProductsBloc>(
      () => ProductsBloc(repository: getIt<ProductRepository>()),
    )
    ..registerFactory<SubscriptionsBloc>(
      () => SubscriptionsBloc(
        repository: getIt<SubscriptionRepository>(),
      ),
    )
    ..registerFactory<EmailBloc>(
      () => EmailBloc(
        emailRepository: getIt<EmailRepository>(),
      ),
    )
    ..registerFactory<FilesCubit>(
      () => FilesCubit(repository: getIt<FileRepository>()),
    )
    ..registerFactory<SearchBloc>(
      () => SearchBloc(repository: getIt<SearchRepository>()),
    )
    ..registerFactory<ReportsCubit>(
      () => ReportsCubit(repository: getIt<ReportRepository>()),
    );

  // ── 9. Router ──────────────────────────────────────────────────
  // ignore: cascade_invocations
  getIt.registerLazySingleton<GoRouter>(
    () => buildAppRouter(
      authStatusStream: getIt<AuthRepository>().status,
      navigatorKey: appNavigatorKey,
      redirect: (context, state) {
        final authState = getIt<AuthBloc>().state;
        final isOnLogin = state.matchedLocation == Routes.login;

        if (authState is AuthAuthenticated && isOnLogin) {
          return Routes.home;
        }
        if (authState is! AuthAuthenticated && !isOnLogin) {
          return Routes.login;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('CIS CRM Home')),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: Routes.contacts,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Contacts')),
          ),
        ),
        GoRoute(
          path: Routes.pipelines,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pipelines')),
          ),
        ),
        GoRoute(
          path: Routes.calendar,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Calendar')),
          ),
        ),
        GoRoute(
          path: Routes.tasks,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Tasks')),
          ),
        ),
        GoRoute(
          path: Routes.products,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Products')),
          ),
        ),
        GoRoute(
          path: Routes.reports,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Reports')),
          ),
        ),
      ],
    ),
  );
}
