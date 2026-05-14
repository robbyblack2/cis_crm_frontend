// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// import 'package:my_flutter_app/core/error/exceptions.dart';
// import 'package:my_flutter_app/core/error/failures.dart';
// import 'package:my_flutter_app/core/error/result.dart';
// import 'package:my_flutter_app/features/example/data/datasources/example_remote_data_source.dart';
// import 'package:my_flutter_app/features/example/data/models/example_model.dart';
// import 'package:my_flutter_app/features/example/data/repositories/example_repository_impl.dart';

class _MockRemoteDataSource extends Mock
    implements ExampleRemoteDataSource {}

void main() {
  group('ExampleRepositoryImpl', () {
    late ExampleRemoteDataSource remote;
    late ExampleRepositoryImpl repository;

    setUp(() {
      remote = _MockRemoteDataSource();
      repository = ExampleRepositoryImpl(remote: remote);
    });

    test('getAll returns Success when data source succeeds', () async {
      final models = [
        const ExampleModel(id: '1', name: 'one'),
      ];
      when(remote.getAll).thenAnswer((_) async => models);

      final result = await repository.getAll();

      expect(result, isA<Success<List<dynamic>, AppFailure>>());
      expect((result as Success).data, equals(models));
    });

    test('getAll converts NetworkException to NetworkFailure', () async {
      when(remote.getAll).thenThrow(const NetworkException());

      final result = await repository.getAll();

      expect(result, isA<Failure<List<dynamic>, AppFailure>>());
      expect((result as Failure).error, isA<NetworkFailure>());
    });

    test('getAll converts ServerException to ServerFailure', () async {
      when(remote.getAll).thenThrow(const ServerException('500', statusCode: 500));

      final result = await repository.getAll();

      expect(result, isA<Failure<List<dynamic>, AppFailure>>());
      final failure = (result as Failure).error;
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, equals(500));
    });

    test('unexpected exceptions become UnknownFailure', () async {
      when(remote.getAll).thenThrow(StateError('boom'));

      final result = await repository.getAll();

      expect(result, isA<Failure<List<dynamic>, AppFailure>>());
      expect((result as Failure).error, isA<UnknownFailure>());
    });
  });
}
