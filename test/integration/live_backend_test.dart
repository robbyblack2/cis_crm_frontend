@Tags(<String>['integration'])
library;

import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source_impl.dart';
import 'package:cis_crm/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cis_crm/features/automation/data/datasources/automation_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/data/datasources/record_remote_data_source.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/reporting/data/datasources/report_remote_datasource.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Live integration tests — run with:
///   flutter test test/integration/ --tags integration
///
/// Requires backend running at localhost:8087.
void main() {
  late Dio dio;

  setUpAll(() async {
    // Plain Dio — no interceptors, no FlutterSecureStorage.
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8087',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    // Login and set token directly on Dio.
    final loginResp = await dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': 'admin@crm.local', 'password': 'admin123'},
    );
    final token =
        (loginResp.data!['data'] as Map<String, dynamic>)['access_token']
            as String;
    dio.options.headers['Authorization'] = 'Bearer $token';
  });

  group('Auth', () {
    test('currentUser parses without crash', () async {
      final ds = AuthRemoteDataSourceImpl(dio);
      final user = await ds.currentUser();
      expect(user.id, isNotEmpty);
      expect(user.email, 'admin@crm.local');
    });
  });

  group('Pipelines', () {
    test('getPipelines parses list', () async {
      final ds = PipelineRemoteDataSourceImpl(dio: dio);
      final result = await ds.getPipelines();
      expect(result, isNotEmpty);
      expect(result.first.id, isNotEmpty);
      expect(result.first.name, isNotEmpty);
    });

    test('getKanban parses stages', () async {
      final ds = PipelineRemoteDataSourceImpl(dio: dio);
      final pipelines = await ds.getPipelines();
      final kanban = await ds.getKanban(pipelines.first.id);
      expect(kanban.stages, isNotEmpty);
    });
  });

  group('Records', () {
    test('getRecords parses list', () async {
      final ds = RecordRemoteDataSourceImpl(dio: dio);
      final result = await ds.getRecords();
      expect(result.items, isNotEmpty);
      expect(result.items.first.title, isNotEmpty);
    });
  });

  group('Contacts', () {
    test('getContacts does not crash', () async {
      final ds = ContactRemoteDataSourceImpl(dio: dio);
      final result = await ds.getContacts();
      // May be empty
      expect(result, isNotNull);
    });
  });

  group('Companies', () {
    test('getCompanies parses list', () async {
      final ds = CompanyRemoteDataSourceImpl(dio: dio);
      final result = await ds.getCompanies();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Tasks', () {
    test('getActivities with type=task handles response', () async {
      final ds = ActivityRemoteDataSourceImpl(dio: dio);
      final result = await ds.getActivities(activityType: 'task');
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Calendar', () {
    test('getEvents handles null data', () async {
      final ds = CalendarRemoteDataSourceImpl(dio: dio);
      final result = await ds.getEvents();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Products', () {
    test('getProducts parses list', () async {
      final ds = ProductRemoteDatasourceImpl(dio: dio);
      final result = await ds.getProducts();
      expect(result, isNotEmpty);
      expect(result.first.name, isNotEmpty);
    });
  });

  group('Subscriptions', () {
    test('getSubscriptions does not crash', () async {
      final ds = SubscriptionRemoteDatasourceImpl(dio: dio);
      final result = await ds.getSubscriptions();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Automation', () {
    test('getRules handles null data', () async {
      final ds = AutomationRemoteDataSourceImpl(dio: dio);
      final result = await ds.getRules();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Email', () {
    test('getDrafts parses list', () async {
      final ds = EmailRemoteDataSourceImpl(dio: dio);
      final result = await ds.getDrafts();
      expect(result, isA<List<dynamic>>());
    });

    test('getTemplates handles null data', () async {
      final ds = EmailRemoteDataSourceImpl(dio: dio);
      final result = await ds.getTemplates();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Reports', () {
    test('getReports handles null data', () async {
      final ds = ReportRemoteDataSourceImpl(dio: dio);
      final result = await ds.getReports();
      expect(result, isA<List<dynamic>>());
    });
  });

  group('Search', () {
    test('search parses grouped response', () async {
      final ds = SearchRemoteDatasourceImpl(dio: dio);
      final result = await ds.search(query: 'test');
      expect(result, isA<List<dynamic>>());
    });
  });
}
