import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContactRepository extends Mock implements ContactRepository {}

void main() {
  late MockContactRepository mockRepository;

  setUp(() {
    mockRepository = MockContactRepository();
  });

  final tContacts = [
    Contact(
      id: '1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      status: 'active',
      tags: const ['vip'],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  group('ContactsBloc', () {
    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getContacts())
            .thenAnswer((_) async => Success(tContacts));
        return ContactsBloc(contactRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ContactsLoadRequested()),
      expect: () => [
        const ContactsLoading(),
        ContactsLoaded(contacts: tContacts),
      ],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsError] when load fails',
      build: () {
        when(() => mockRepository.getContacts()).thenAnswer(
          (_) async => const Failure(
            ServerFailure('Server error', statusCode: 500),
          ),
        );
        return ContactsBloc(contactRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ContactsLoadRequested()),
      expect: () => [
        const ContactsLoading(),
        const ContactsError(
          failure: ServerFailure('Server error', statusCode: 500),
        ),
      ],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsError] '
      'when load returns network failure',
      build: () {
        when(() => mockRepository.getContacts())
            .thenAnswer((_) async => const Failure(NetworkFailure()));
        return ContactsBloc(contactRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ContactsLoadRequested()),
      expect: () => [
        const ContactsLoading(),
        const ContactsError(failure: NetworkFailure()),
      ],
    );
  });
}
