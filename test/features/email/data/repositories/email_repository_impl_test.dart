import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/email/data/models/email_draft_model.dart';
import 'package:cis_crm/features/email/data/models/email_message_model.dart';
import 'package:cis_crm/features/email/data/models/email_template_model.dart';
import 'package:cis_crm/features/email/data/repositories/email_repository_impl.dart';
import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmailRemoteDataSource extends Mock implements EmailRemoteDataSource {}

void main() {
  late MockEmailRemoteDataSource mockDataSource;
  late EmailRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockEmailRemoteDataSource();
    repository = EmailRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final tMessageModel = EmailMessageModel(
    id: '1',
    direction: EmailDirection.outbound,
    senderEmail: 'me@test.com',
    recipientEmails: const ['you@test.com'],
    subject: 'Test',
    body: 'Body',
    createsRecord: false,
    timestamp: DateTime(2026),
  );

  final tDraftModel = EmailDraftModel(
    id: 'd1',
    recipientEmails: const ['you@test.com'],
    subject: 'Draft',
    body: 'Draft body',
    createdBy: 'user1',
    createdAt: DateTime(2026),
  );

  final tTemplateModel = EmailTemplateModel(
    id: 't1',
    name: 'Welcome',
    subjectTemplate: 'Welcome!',
    bodyTemplate: 'Hello',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('sendEmail', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.sendEmail(
          recipientEmails: any(named: 'recipientEmails'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => tMessageModel);

      final result = await repository.sendEmail(
        recipientEmails: const ['you@test.com'],
        subject: 'Test',
        body: 'Body',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(tMessageModel));
    });

    test('returns Failure when data source throws ServerException', () async {
      when(
        () => mockDataSource.sendEmail(
          recipientEmails: any(named: 'recipientEmails'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenThrow(const ServerException('Server error', statusCode: 500));

      final result = await repository.sendEmail(
        recipientEmails: const ['you@test.com'],
        subject: 'Test',
        body: 'Body',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns NetworkFailure when data source throws NetworkException',
        () async {
      when(
        () => mockDataSource.sendEmail(
          recipientEmails: any(named: 'recipientEmails'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.sendEmail(
        recipientEmails: const ['you@test.com'],
        subject: 'Test',
        body: 'Body',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('saveDraft', () {
    test('returns Success when data source succeeds', () async {
      when(
        () => mockDataSource.saveDraft(
          recipientEmails: any(named: 'recipientEmails'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => tDraftModel);

      final result = await repository.saveDraft(
        recipientEmails: const ['you@test.com'],
        subject: 'Draft',
        body: 'Draft body',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(tDraftModel));
    });

    test('returns Failure on exception', () async {
      when(
        () => mockDataSource.saveDraft(
          recipientEmails: any(named: 'recipientEmails'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
        ),
      ).thenThrow(const ServerException('Failed'));

      final result = await repository.saveDraft(
        recipientEmails: const ['you@test.com'],
        subject: 'Draft',
        body: 'Draft body',
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('getDrafts', () {
    test('returns Success with list when data source succeeds', () async {
      when(() => mockDataSource.getDrafts())
          .thenAnswer((_) async => [tDraftModel]);

      final result = await repository.getDrafts();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals([tDraftModel]));
    });
  });

  group('getTemplates', () {
    test('returns Success with list when data source succeeds', () async {
      when(() => mockDataSource.getTemplates())
          .thenAnswer((_) async => [tTemplateModel]);

      final result = await repository.getTemplates();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals([tTemplateModel]));
    });
  });

  group('deleteTemplate', () {
    test('returns Success<void> when data source succeeds', () async {
      when(() => mockDataSource.deleteTemplate(id: any(named: 'id')))
          .thenAnswer((_) async {});

      final result = await repository.deleteTemplate(id: 't1');

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when data source throws', () async {
      when(() => mockDataSource.deleteTemplate(id: any(named: 'id')))
          .thenThrow(const ServerException('Delete failed'));

      final result = await repository.deleteTemplate(id: 't1');

      expect(result.isFailure, isTrue);
    });
  });
}
