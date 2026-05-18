import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contact_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';

class MockContactRepository extends Mock implements ContactRepository {}

class FakeContact extends Fake implements Contact {}

void main() {
  late MockContactRepository mockRepo;

  final now = DateTime(2024);
  final testContact = Contact(
    id: 'c1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    phone: '555-1234',
    jobTitle: 'Engineer',
    source: 'web',
    status: 'active',
    tags: const ['vip'],
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeContact());
  });

  setUp(() {
    mockRepo = MockContactRepository();
  });

  group('ContactFormCubit', () {
    test('initial state has empty fields in create mode', () {
      final cubit = ContactFormCubit(contactRepository: mockRepo);
      expect(cubit.isEditing, isFalse);
      expect(cubit.state.firstName.value, isEmpty);
      expect(cubit.state.lastName.value, isEmpty);
      cubit.close();
    });

    test('initial state is pre-filled in edit mode', () {
      final cubit = ContactFormCubit(
        contactRepository: mockRepo,
        existingContact: testContact,
      );
      expect(cubit.isEditing, isTrue);
      expect(cubit.state.firstName.value, 'John');
      expect(cubit.state.lastName.value, 'Doe');
      expect(cubit.state.email, 'john@example.com');
      expect(cubit.state.phone, '555-1234');
      expect(cubit.state.jobTitle, 'Engineer');
      expect(cubit.state.source, 'web');
      cubit.close();
    });

    blocTest<ContactFormCubit, ContactFormState>(
      'submitted calls createContact in create mode on success',
      setUp: () {
        when(() => mockRepo.createContact(any()))
            .thenAnswer((_) async => Success(testContact));
      },
      build: () => ContactFormCubit(contactRepository: mockRepo),
      act: (cubit) {
        cubit
          ..firstNameChanged('Jane')
          ..lastNameChanged('Smith')
          ..emailChanged('jane@example.com');
        return cubit.submitted();
      },
      expect: () => [
        isA<ContactFormState>(), // firstName dirty
        isA<ContactFormState>(), // lastName dirty
        isA<ContactFormState>(), // email
        isA<ContactFormState>(), // validation
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.success,
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.createContact(any())).called(1);
        verifyNever(() => mockRepo.updateContact(any()));
      },
    );

    blocTest<ContactFormCubit, ContactFormState>(
      'submitted calls updateContact in edit mode on success',
      setUp: () {
        when(() => mockRepo.updateContact(any()))
            .thenAnswer((_) async => Success(testContact));
      },
      build: () => ContactFormCubit(
        contactRepository: mockRepo,
        existingContact: testContact,
      ),
      act: (cubit) {
        cubit.firstNameChanged('Johnny');
        return cubit.submitted();
      },
      expect: () => [
        isA<ContactFormState>(), // firstName dirty
        isA<ContactFormState>(), // validation
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.success,
            ),
      ],
      verify: (_) {
        verify(() => mockRepo.updateContact(any())).called(1);
        verifyNever(() => mockRepo.createContact(any()));
      },
    );

    blocTest<ContactFormCubit, ContactFormState>(
      'submitted emits failure when update fails',
      setUp: () {
        when(() => mockRepo.updateContact(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('Update failed')),
        );
      },
      build: () => ContactFormCubit(
        contactRepository: mockRepo,
        existingContact: testContact,
      ),
      act: (cubit) => cubit.submitted(),
      expect: () => [
        isA<ContactFormState>(), // validation
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.inProgress,
            ),
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
    );

    blocTest<ContactFormCubit, ContactFormState>(
      'submitted emits failure when names are empty',
      build: () => ContactFormCubit(contactRepository: mockRepo),
      act: (cubit) => cubit.submitted(),
      expect: () => [
        isA<ContactFormState>(), // validation
        isA<ContactFormState>()
            .having(
              (s) => s.submissionStatus,
              'submissionStatus',
              FormzSubmissionStatus.failure,
            ),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.createContact(any()));
        verifyNever(() => mockRepo.updateContact(any()));
      },
    );
  });
}
