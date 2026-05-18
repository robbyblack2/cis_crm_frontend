import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:cis_crm/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockContactRemoteDataSource extends Mock
    implements ContactRemoteDataSource {}

void main() {
  late MockContactRemoteDataSource mockDataSource;
  late ContactRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockContactRemoteDataSource();
    repository = ContactRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final tContactModel = ContactModel(
    id: '1',
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    status: 'active',
    tags: const ['vip'],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final tPaginatedResponse = PaginatedResponse<ContactModel>(
    items: [tContactModel],
    page: 1,
    perPage: 25,
    total: 1,
  );

  group('getContacts', () {
    test('returns Success with paginated contacts when data source succeeds',
        () async {
      when(() => mockDataSource.getContacts(page: 1, perPage: 25))
          .thenAnswer((_) async => tPaginatedResponse);

      final result = await repository.getContacts();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.items, equals([tContactModel]));
      expect(result.dataOrNull!.total, equals(1));
      expect(result.dataOrNull!.page, equals(1));
      verify(() => mockDataSource.getContacts(page: 1, perPage: 25)).called(1);
    });

    test('passes page and perPage to data source', () async {
      final page2Response = PaginatedResponse<ContactModel>(
        items: [tContactModel],
        page: 2,
        perPage: 10,
        total: 15,
      );
      when(() => mockDataSource.getContacts(page: 2, perPage: 10))
          .thenAnswer((_) async => page2Response);

      final result = await repository.getContacts(page: 2, perPage: 10);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.page, equals(2));
      expect(result.dataOrNull!.perPage, equals(10));
      verify(() => mockDataSource.getContacts(page: 2, perPage: 10)).called(1);
    });

    test('returns Failure(ServerFailure) when ServerException is thrown',
        () async {
      when(() => mockDataSource.getContacts(page: 1, perPage: 25))
          .thenThrow(const ServerException('Server error', statusCode: 500));

      final result = await repository.getContacts();

      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull,
        isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Server error')
            .having((f) => f.statusCode, 'statusCode', 500),
      );
    });

    test('returns Failure(NetworkFailure) when NetworkException is thrown',
        () async {
      when(() => mockDataSource.getContacts(page: 1, perPage: 25))
          .thenThrow(const NetworkException());

      final result = await repository.getContacts();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test(
        'returns Failure(UnauthorizedFailure) when '
        'UnauthorizedException is thrown', () async {
      when(() => mockDataSource.getContacts(page: 1, perPage: 25))
          .thenThrow(const UnauthorizedException());

      final result = await repository.getContacts();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('deleteContact', () {
    test('returns Success(null) when data source succeeds', () async {
      when(() => mockDataSource.deleteContact('1')).thenAnswer((_) async => {});

      final result = await repository.deleteContact('1');

      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.deleteContact('1')).called(1);
    });

    test('returns Failure when data source throws', () async {
      when(() => mockDataSource.deleteContact('1'))
          .thenThrow(const ServerException('Not found', statusCode: 404));

      final result = await repository.deleteContact('1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
