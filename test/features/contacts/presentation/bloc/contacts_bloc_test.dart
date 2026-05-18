import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
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

  final tPaginatedResponse = PaginatedResponse<Contact>(
    items: tContacts,
    page: 1,
    perPage: 25,
    total: 1,
  );

  group('ContactsBloc', () {
    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getContacts(page: 1, perPage: 25))
            .thenAnswer((_) async => Success(tPaginatedResponse));
        return ContactsBloc(contactRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ContactsLoadRequested()),
      expect: () => [
        const ContactsLoading(),
        ContactsLoaded(
          contacts: tContacts,
          currentPage: 1,
          total: 1,
          perPage: 25,
        ),
      ],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsError] when load fails',
      build: () {
        when(() => mockRepository.getContacts(page: 1, perPage: 25))
            .thenAnswer(
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
        when(() => mockRepository.getContacts(page: 1, perPage: 25))
            .thenAnswer((_) async => const Failure(NetworkFailure()));
        return ContactsBloc(contactRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ContactsLoadRequested()),
      expect: () => [
        const ContactsLoading(),
        const ContactsError(failure: NetworkFailure()),
      ],
    );

    group('ContactsLoadMoreRequested', () {
      final tMoreContacts = [
        Contact(
          id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@example.com',
          status: 'active',
          tags: const [],
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final tPage2Response = PaginatedResponse<Contact>(
        items: tMoreContacts,
        page: 2,
        perPage: 25,
        total: 50,
      );

      blocTest<ContactsBloc, ContactsState>(
        'appends items when load more succeeds',
        seed: () => ContactsLoaded(
          contacts: tContacts,
          currentPage: 1,
          total: 50,
          perPage: 25,
        ),
        build: () {
          when(() => mockRepository.getContacts(page: 2, perPage: 25))
              .thenAnswer((_) async => Success(tPage2Response));
          return ContactsBloc(contactRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const ContactsLoadMoreRequested()),
        expect: () => [
          ContactsLoaded(
            contacts: tContacts,
            currentPage: 1,
            total: 50,
            perPage: 25,
            isLoadingMore: true,
          ),
          ContactsLoaded(
            contacts: [...tContacts, ...tMoreContacts],
            currentPage: 2,
            total: 50,
            perPage: 25,
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getContacts(page: 2, perPage: 25))
              .called(1);
        },
      );

      blocTest<ContactsBloc, ContactsState>(
        'does nothing when there are no more pages',
        seed: () => ContactsLoaded(
          contacts: tContacts,
          currentPage: 1,
          total: 1,
          perPage: 25,
        ),
        build: () => ContactsBloc(contactRepository: mockRepository),
        act: (bloc) => bloc.add(const ContactsLoadMoreRequested()),
        expect: () => <ContactsState>[],
      );

      blocTest<ContactsBloc, ContactsState>(
        'does nothing when state is not ContactsLoaded',
        build: () => ContactsBloc(contactRepository: mockRepository),
        act: (bloc) => bloc.add(const ContactsLoadMoreRequested()),
        expect: () => <ContactsState>[],
      );
    });
  });
}
