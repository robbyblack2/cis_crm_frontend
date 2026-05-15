import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:cis_crm/features/search/data/models/search_result_model.dart';
import 'package:cis_crm/features/search/data/repositories/search_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchRemoteDatasource extends Mock
    implements SearchRemoteDatasource {}

void main() {
  late MockSearchRemoteDatasource mockDatasource;
  late SearchRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockSearchRemoteDatasource();
    repository = SearchRepositoryImpl(datasource: mockDatasource);
  });

  const tModels = [
    SearchResultModel(
      id: '1',
      entityType: 'contact',
      title: 'John Doe',
      subtitle: 'john@example.com',
      matchedField: 'name',
    ),
  ];

  group('search', () {
    test('returns Success with results when datasource succeeds', () async {
      when(
        () => mockDatasource.search(query: any(named: 'query')),
      ).thenAnswer((_) async => tModels);

      final result = await repository.search(query: 'john');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tModels);
      verify(() => mockDatasource.search(query: 'john')).called(1);
    });

    test('returns Failure(ServerFailure) when ServerException is thrown',
        () async {
      when(
        () => mockDatasource.search(query: any(named: 'query')),
      ).thenThrow(const ServerException('Server error', statusCode: 500));

      final result = await repository.search(query: 'john');

      expect(result.isFailure, isTrue);
      final failure = result.failureOrNull;
      expect(failure, isA<ServerFailure>());
      expect((failure! as ServerFailure).statusCode, 500);
    });

    test('returns Failure(NetworkFailure) when NetworkException is thrown',
        () async {
      when(
        () => mockDatasource.search(query: any(named: 'query')),
      ).thenThrow(const NetworkException());

      final result = await repository.search(query: 'john');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test(
        'returns Failure(UnauthorizedFailure) when UnauthorizedException '
        'is thrown', () async {
      when(
        () => mockDatasource.search(query: any(named: 'query')),
      ).thenThrow(const UnauthorizedException());

      final result = await repository.search(query: 'john');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('passes type parameter to datasource when provided', () async {
      when(
        () => mockDatasource.search(
          query: any(named: 'query'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => tModels);

      await repository.search(query: 'john', type: 'contact');

      verify(
        () => mockDatasource.search(query: 'john', type: 'contact'),
      ).called(1);
    });
  });
}
