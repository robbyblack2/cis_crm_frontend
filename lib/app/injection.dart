import 'package:cis_crm/app/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cis_crm/core/analytics/analytics_service.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:cis_crm/core/flags/feature_flag_service.dart';
import 'package:cis_crm/core/logging/app_logger.dart';
import 'package:cis_crm/core/network/auth_api.dart';
import 'package:cis_crm/core/network/dio_client.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/network/web_socket_service.dart';
import 'package:cis_crm/core/observability/app_bloc_observer.dart';
import 'package:cis_crm/core/router/app_router.dart';
import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/core/router/shell.dart';
import 'package:cis_crm/core/theme/theme_cubit.dart';
import 'package:cis_crm/core/widgets/adaptive_scaffold.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/calendar_activity_repository_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/call_log_repository_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/task_repository_impl.dart';
import 'package:cis_crm/features/activity/data/repositories/timeline_repository_impl.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/domain/repositories/timeline_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/pages/tasks_page.dart';
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
import 'package:cis_crm/features/calendar/presentation/pages/calendar_page.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/repositories/company_repository_impl.dart';
import 'package:cis_crm/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:cis_crm/features/contacts/presentation/pages/contacts_page.dart';
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
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_management_page.dart';
import 'package:cis_crm/features/pipeline/presentation/pages/pipeline_page.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/products/data/repositories/product_repository_impl.dart';
import 'package:cis_crm/features/products/data/repositories/subscription_repository_impl.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';
import 'package:cis_crm/features/products/domain/repositories/subscription_repository.dart';
import 'package:cis_crm/features/products/presentation/bloc/products_bloc.dart';
import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:cis_crm/features/products/presentation/pages/products_page.dart';
import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:cis_crm/features/reporting/domain/repositories/report_repository.dart';
import 'package:cis_crm/features/reporting/presentation/bloc/reports_cubit.dart';
import 'package:cis_crm/features/reporting/presentation/pages/reports_page.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:cis_crm/features/search/data/repositories/search_repository_impl.dart';
import 'package:cis_crm/features/search/domain/repositories/search_repository.dart';
import 'package:cis_crm/features/search/presentation/bloc/search_bloc.dart';
import 'package:cis_crm/features/activity/presentation/pages/call_log_page.dart';
import 'package:cis_crm/features/automation/presentation/pages/automation_page.dart';
import 'package:cis_crm/features/contacts/presentation/pages/companies_page.dart';
import 'package:cis_crm/features/email/presentation/pages/email_compose_page.dart';
import 'package:cis_crm/features/email/presentation/pages/email_templates_page.dart';
import 'package:cis_crm/features/files/presentation/pages/files_page.dart';
import 'package:cis_crm/features/search/presentation/pages/search_page.dart';
import 'package:cis_crm/features/settings/data/datasources/google_remote_data_source.dart';
import 'package:cis_crm/features/settings/presentation/pages/email_signature_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/field_definitions_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/import_export_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/saved_views_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/tags_page.dart';
import 'package:cis_crm/features/settings/data/repositories/google_repository_impl.dart';
import 'package:cis_crm/features/settings/domain/repositories/google_repository.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_cubit.dart';
import 'package:cis_crm/features/settings/presentation/pages/audit_log_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/integrations_page.dart';
import 'package:cis_crm/features/activity/presentation/pages/activity_statuses_page.dart';
import 'package:cis_crm/features/activity/presentation/pages/activity_subtypes_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/gdpr_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/roles_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/users_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/profile_page.dart';
import 'package:cis_crm/features/settings/presentation/pages/settings_page.dart';
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

  // ignore: cascade_invocations
  getIt.registerLazySingleton<WebSocketService>(
    () => WebSocketService(
      baseUrl: config.apiBaseUrl,
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  // ignore: cascade_invocations
  getIt.registerLazySingleton<WebSocketCubit>(
    () => WebSocketCubit(getIt<WebSocketService>()),
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
    )
    ..registerLazySingleton<GoogleRemoteDataSource>(
      () => GoogleRemoteDataSourceImpl(dio: dio),
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
    ..registerLazySingleton<CalendarActivityRepository>(
      () => CalendarActivityRepositoryImpl(
        remoteDataSource: getIt<ActivityRemoteDataSource>(),
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
    )
    ..registerLazySingleton<TimelineRepository>(
      () => TimelineRepositoryImpl(
        remoteDataSource: getIt<ActivityRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<GoogleRepository>(
      () => GoogleRepositoryImpl(
        remoteDataSource: getIt<GoogleRemoteDataSource>(),
      ),
    );

  // ── 7. App-wide blocs (singletons) ─────────────────────────────
  // ignore: cascade_invocations
  getIt
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new);

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
      () => CalendarBloc(
        repository: getIt<CalendarRepository>(),
      ),
    )
    ..registerFactory<TasksBloc>(
      () => TasksBloc(
        taskRepository: getIt<TaskRepository>(),
      ),
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
      () => ProductsBloc(
        repository: getIt<ProductRepository>(),
      ),
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
      () => FilesCubit(
        repository: getIt<FileRepository>(),
      ),
    )
    ..registerFactory<SearchBloc>(
      () => SearchBloc(
        repository: getIt<SearchRepository>(),
      ),
    )
    ..registerFactory<ReportsCubit>(
      () => ReportsCubit(
        repository: getIt<ReportRepository>(),
      ),
    )
    ..registerFactory<GoogleIntegrationCubit>(
      () => GoogleIntegrationCubit(
        repository: getIt<GoogleRepository>(),
      ),
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
          path: Routes.login,
          builder: (context, state) => const LoginPage(),
        ),
        buildAdaptiveShell(
          destinations: const [
            AdaptiveDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Pipeline',
            ),
            AdaptiveDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            AdaptiveDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Activities',
            ),
            AdaptiveDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            AdaptiveDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.home,
                  builder: (_, __) => const PipelinePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.contacts,
                  builder: (_, __) => const ContactsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.tasks,
                  builder: (_, __) => const TasksPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.products,
                  builder: (_, __) => const ProductsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.reports,
                  builder: (_, __) => const ReportsPage(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: Routes.settings,
          builder: (_, __) => const SettingsPage(),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (_, __) => const ProfilePage(),
        ),
        GoRoute(
          path: Routes.search,
          builder: (_, __) => const SearchPage(),
        ),
        GoRoute(
          path: Routes.integrations,
          builder: (_, __) => const IntegrationsPage(),
        ),
        GoRoute(
          path: Routes.automation,
          builder: (_, __) => const AutomationPage(),
        ),
        GoRoute(
          path: Routes.companies,
          builder: (_, __) => const CompaniesPage(),
        ),
        GoRoute(
          path: Routes.emailTemplates,
          builder: (_, __) => const EmailTemplatesPage(),
        ),
        GoRoute(
          path: Routes.emailCompose,
          builder: (_, __) => const EmailComposePage(),
        ),
        GoRoute(
          path: Routes.callLogs,
          builder: (_, __) => const CallLogPage(),
        ),
        GoRoute(
          path: Routes.files,
          builder: (_, __) => const FilesPage(),
        ),
        GoRoute(
          path: Routes.users,
          builder: (_, __) => const UsersPage(),
        ),
        GoRoute(
          path: Routes.roles,
          builder: (_, __) => const RolesPage(),
        ),
        GoRoute(
          path: Routes.activityStatuses,
          builder: (_, __) => const ActivityStatusesPage(),
        ),
        GoRoute(
          path: Routes.activitySubtypes,
          builder: (_, __) => const ActivitySubtypesPage(),
        ),
        GoRoute(
          path: Routes.gdpr,
          builder: (_, __) => const GdprPage(),
        ),
        GoRoute(
          path: Routes.auditLog,
          builder: (_, __) => const AuditLogPage(),
        ),
        GoRoute(
          path: Routes.importExport,
          builder: (_, __) => const ImportExportPage(),
        ),
        GoRoute(
          path: Routes.pipelineManagement,
          builder: (_, __) => BlocProvider.value(
            value: getIt<PipelineBloc>(),
            child: const PipelineManagementPage(),
          ),
        ),
        GoRoute(
          path: Routes.fieldDefinitions,
          builder: (_, __) => const FieldDefinitionsPage(),
        ),
        GoRoute(
          path: Routes.tags,
          builder: (_, __) => const TagsPage(),
        ),
        GoRoute(
          path: Routes.savedViews,
          builder: (_, __) => const SavedViewsPage(),
        ),
        GoRoute(
          path: Routes.emailSignature,
          builder: (_, __) => const EmailSignaturePage(),
        ),
      ],
    ),
  );
}
