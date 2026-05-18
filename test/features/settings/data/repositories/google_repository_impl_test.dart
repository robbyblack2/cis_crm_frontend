import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/settings/data/datasources/google_remote_data_source.dart';
import 'package:cis_crm/features/settings/data/models/google_connection_model.dart';
import 'package:cis_crm/features/settings/data/repositories/google_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleRemoteDataSource extends Mock
    implements GoogleRemoteDataSource {}

void main() {
  late MockGoogleRemoteDataSource mockDataSource;
  late GoogleRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockGoogleRemoteDataSource();
    repository = GoogleRepositoryImpl(remoteDataSource: mockDataSource);
  });

  DioException dioError(AppException appException) => DioException(
        requestOptions: RequestOptions(),
        error: appException,
      );

  const tConnectionModel = GoogleConnectionModel(
    connected: true,
    email: 'user@gmail.com',
  );

  group('getAuthUrl', () {
    test('returns Success with auth URL on success', () async {
      when(() => mockDataSource.getAuthUrl())
          .thenAnswer((_) async => 'https://accounts.google.com/auth');

      final result = await repository.getAuthUrl();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'https://accounts.google.com/auth');
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => mockDataSource.getAuthUrl())
          .thenThrow(dioError(const NetworkException()));

      final result = await repository.getAuthUrl();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getAuthUrl())
          .thenThrow(dioError(const ServerException('fail', statusCode: 500)));

      final result = await repository.getAuthUrl();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns Failure(UnauthorizedFailure) on UnauthorizedException',
      () async {
        when(() => mockDataSource.getAuthUrl())
            .thenThrow(dioError(const UnauthorizedException()));

        final result = await repository.getAuthUrl();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      },
    );

    test('returns Failure(UnknownFailure) on unknown DioException', () async {
      when(() => mockDataSource.getAuthUrl()).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      final result = await repository.getAuthUrl();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('getStatus', () {
    test('returns Success with GoogleConnection on success', () async {
      when(() => mockDataSource.getStatus())
          .thenAnswer((_) async => tConnectionModel);

      final result = await repository.getStatus();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tConnectionModel);
    });

    test('returns Failure on error', () async {
      when(() => mockDataSource.getStatus())
          .thenThrow(dioError(const ServerException('fail')));

      final result = await repository.getStatus();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('disconnect', () {
    test('returns Success(null) on success', () async {
      when(() => mockDataSource.disconnect()).thenAnswer((_) async {});

      final result = await repository.disconnect();

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure on error', () async {
      when(() => mockDataSource.disconnect())
          .thenThrow(dioError(const NetworkException()));

      final result = await repository.disconnect();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
