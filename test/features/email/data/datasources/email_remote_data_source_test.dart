import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/email/data/models/email_draft_model.dart';
import 'package:cis_crm/features/email/data/models/email_message_model.dart';
import 'package:cis_crm/features/email/data/models/email_template_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late EmailRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = EmailRemoteDataSourceImpl(dio: mockDio);
  });

  group('sendEmail', () {
    final tResponseData = <String, dynamic>{
      'id': '1',
      'direction': 'outbound',
      'from_address': 'me@test.com',
      'to_addresses': ['you@test.com'],
      'subject': 'Test',
      'body_html': 'Body',
      'creates_record': false,
      'created_at': '2026-01-01T00:00:00.000',
    };

    test('returns EmailMessageModel on success', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.sendEmail(
        recipientEmails: const ['you@test.com'],
        subject: 'Test',
        body: 'Body',
      );

      expect(result, isA<EmailMessageModel>());
      expect(result.id, '1');
    });

    test('throws ServerException on DioException', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          message: 'Internal server error',
        ),
      );

      expect(
        () => dataSource.sendEmail(
          recipientEmails: const ['you@test.com'],
          subject: 'Test',
          body: 'Body',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getDrafts', () {
    test('returns list of EmailDraftModel on success', () async {
      final tDraftData = <dynamic>[
        {
          'id': 'd1',
          'to_addresses': ['you@test.com'],
          'subject': 'Draft',
          'body_html': 'Draft body',
          'sent_by_user_id': 'user1',
          'created_at': '2026-01-01T00:00:00.000',
        },
      ];

      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: tDraftData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getDrafts();

      expect(result, isA<List<EmailDraftModel>>());
      expect(result, hasLength(1));
    });
  });

  group('getTemplates', () {
    test('returns list of EmailTemplateModel on success', () async {
      final tTemplateData = <dynamic>[
        {
          'id': 't1',
          'name': 'Welcome',
          'subject': 'Welcome!',
          'body': 'Hello',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        },
      ];

      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: tTemplateData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getTemplates();

      expect(result, isA<List<EmailTemplateModel>>());
      expect(result, hasLength(1));
    });
  });

  group('deleteTemplate', () {
    test('completes successfully', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(
        dataSource.deleteTemplate(id: 't1'),
        completes,
      );
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Delete failed',
        ),
      );

      expect(
        () => dataSource.deleteTemplate(id: 't1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
