import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
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

  group('getContacts', () {
    test('returns Success with contacts when data source succeeds', () async {
      when(() => mockDataSource.getContacts())
          .thenAnswer((_) async => [tContactModel]);

      final result = await repository.getContacts();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals([tContactModel]));
      verify(() => mockDataSource.getContacts()).called(1);
    });

    test('returns Failure(ServerFailure) when ServerException is thrown',
        () async {
      when(() => mockDataSource.getContacts())
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
      when(() => mockDataSource.getContacts())
          .thenThrow(const NetworkException());

      final result = await repository.getContacts();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test(
        'returns Failure(UnauthorizedFailure) when '
        'UnauthorizedException is thrown', () async {
      when(() => mockDataSource.getContacts())
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
