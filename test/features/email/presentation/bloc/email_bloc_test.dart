import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/email/domain/entities/email_direction.dart';
import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:cis_crm/features/email/domain/repositories/email_repository.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmailRepository extends Mock implements EmailRepository {}

void main() {
  late MockEmailRepository mockRepository;

  setUp(() {
    mockRepository = MockEmailRepository();
  });

  final tMessage = EmailMessage(
    id: '1',
    direction: EmailDirection.outbound,
    senderEmail: 'me@test.com',
    recipientEmails: const ['you@test.com'],
    subject: 'Test',
    body: 'Body',
    createsRecord: false,
    timestamp: DateTime(2026),
  );

  final tDraft = EmailDraft(
    id: 'd1',
    recipientEmails: const ['you@test.com'],
    subject: 'Draft',
    body: 'Draft body',
    createdBy: 'user1',
    createdAt: DateTime(2026),
  );

  final tTemplate = EmailTemplate(
    id: 't1',
    name: 'Welcome',
    subject: 'Welcome!',
    body: 'Hello',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('EmailBloc', () {
    group('EmailSendRequested', () {
      blocTest<EmailBloc, EmailState>(
        'emits [loading, loaded] when send succeeds',
        build: () {
          when(
            () => mockRepository.sendEmail(
              recipientEmails: any(named: 'recipientEmails'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => Success(tMessage));
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSendRequested(
            recipientEmails: ['you@test.com'],
            subject: 'Test',
            body: 'Body',
          ),
        ),
        expect: () => [
          const EmailLoading(),
          EmailLoaded(sentMessage: tMessage),
        ],
      );

      blocTest<EmailBloc, EmailState>(
        'emits [loading, error] when send fails',
        build: () {
          when(
            () => mockRepository.sendEmail(
              recipientEmails: any(named: 'recipientEmails'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('Send failed')),
          );
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSendRequested(
            recipientEmails: ['you@test.com'],
            subject: 'Test',
            body: 'Body',
          ),
        ),
        expect: () => [
          const EmailLoading(),
          const EmailError(failure: ServerFailure('Send failed')),
        ],
      );
    });

    group('DraftSaveRequested', () {
      blocTest<EmailBloc, EmailState>(
        'emits [loading, loaded] when save succeeds',
        build: () {
          when(
            () => mockRepository.saveDraft(
              recipientEmails: any(named: 'recipientEmails'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => Success(tDraft));
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const DraftSaveRequested(
            recipientEmails: ['you@test.com'],
            subject: 'Draft',
            body: 'Draft body',
          ),
        ),
        expect: () => [
          const EmailLoading(),
          EmailLoaded(savedDraft: tDraft),
        ],
      );

      blocTest<EmailBloc, EmailState>(
        'emits [loading, error] when save fails',
        build: () {
          when(
            () => mockRepository.saveDraft(
              recipientEmails: any(named: 'recipientEmails'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('Save failed')),
          );
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const DraftSaveRequested(
            recipientEmails: ['you@test.com'],
            subject: 'Draft',
            body: 'Draft body',
          ),
        ),
        expect: () => [
          const EmailLoading(),
          const EmailError(failure: ServerFailure('Save failed')),
        ],
      );
    });

    group('DraftSendRequested', () {
      blocTest<EmailBloc, EmailState>(
        'emits [loading, loaded] when draft send succeeds',
        build: () {
          when(() => mockRepository.sendDraft(id: any(named: 'id')))
              .thenAnswer((_) async => Success(tMessage));
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const DraftSendRequested(draftId: 'd1')),
        expect: () => [
          const EmailLoading(),
          EmailLoaded(sentMessage: tMessage),
        ],
      );

      blocTest<EmailBloc, EmailState>(
        'emits [loading, error] when draft send fails',
        build: () {
          when(() => mockRepository.sendDraft(id: any(named: 'id'))).thenAnswer(
            (_) async => const Failure(ServerFailure('Draft send failed')),
          );
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const DraftSendRequested(draftId: 'd1')),
        expect: () => [
          const EmailLoading(),
          const EmailError(failure: ServerFailure('Draft send failed')),
        ],
      );
    });

    group('TemplateCreateRequested', () {
      blocTest<EmailBloc, EmailState>(
        'emits [loading, loaded] when template create + reload succeeds',
        build: () {
          when(
            () => mockRepository.createTemplate(
              name: any(named: 'name'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => Success(tTemplate));
          when(() => mockRepository.getTemplates())
              .thenAnswer((_) async => Success([tTemplate]));
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const TemplateCreateRequested(
            name: 'Welcome',
            subject: 'Welcome!',
            body: 'Hello',
          ),
        ),
        expect: () => [
          const EmailLoading(),
          EmailLoaded(templates: [tTemplate]),
        ],
      );

      blocTest<EmailBloc, EmailState>(
        'emits [loading, error] when template create fails',
        build: () {
          when(
            () => mockRepository.createTemplate(
              name: any(named: 'name'),
              subject: any(named: 'subject'),
              body: any(named: 'body'),
            ),
          ).thenAnswer(
            (_) async => const Failure(ServerFailure('Create failed')),
          );
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const TemplateCreateRequested(
            name: 'Welcome',
            subject: 'Welcome!',
            body: 'Hello',
          ),
        ),
        expect: () => const [
          EmailLoading(),
          EmailError(failure: ServerFailure('Create failed')),
        ],
      );
    });

    group('TemplatesLoadRequested', () {
      blocTest<EmailBloc, EmailState>(
        'emits [loading, loaded] when templates load succeeds',
        build: () {
          when(() => mockRepository.getTemplates())
              .thenAnswer((_) async => Success([tTemplate]));
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const TemplatesLoadRequested()),
        expect: () => [
          const EmailLoading(),
          EmailLoaded(templates: [tTemplate]),
        ],
      );

      blocTest<EmailBloc, EmailState>(
        'emits [loading, error] when templates load fails',
        build: () {
          when(() => mockRepository.getTemplates()).thenAnswer(
            (_) async => const Failure(ServerFailure('Load failed')),
          );
          return EmailBloc(emailRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const TemplatesLoadRequested()),
        expect: () => [
          const EmailLoading(),
          const EmailError(failure: ServerFailure('Load failed')),
        ],
      );
    });
  });
}
