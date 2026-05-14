import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/example_entity.dart';
import '../../domain/repositories/example_repository.dart';
import '../datasources/example_remote_data_source.dart';

/// Concrete repository for the `example` feature.
///
/// Catches [AppException]s from the data source, converts to [AppFailure],
/// and returns `Result<T, AppFailure>` so the bloc can switch on outcomes
/// without try/catch.
class ExampleRepositoryImpl implements ExampleRepository {
  ExampleRepositoryImpl({required ExampleRemoteDataSource remote})
      : _remote = remote;

  final ExampleRemoteDataSource _remote;

  @override
  Future<Result<List<ExampleEntity>, AppFailure>> getAll() async {
    try {
      final list = await _remote.getAll();
      return Success(list);
    } on AppException catch (e) {
      return Failure(_toFailure(e));
    } catch (e) {
      return Failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<ExampleEntity, AppFailure>> getById(String id) async {
    try {
      final model = await _remote.getById(id);
      return Success(model);
    } on AppException catch (e) {
      return Failure(_toFailure(e));
    } catch (e) {
      return Failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<ExampleEntity, AppFailure>> create(
    ExampleEntity entity,
  ) async {
    try {
      final model = await _remote.create(
        // Domain → DTO. Adapt if your entity ≠ model shape.
        await _toModel(entity),
      );
      return Success(model);
    } on AppException catch (e) {
      return Failure(_toFailure(e));
    } catch (e) {
      return Failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    try {
      await _remote.delete(id);
      return const Success(null);
    } on AppException catch (e) {
      return Failure(_toFailure(e));
    } catch (e) {
      return Failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  AppFailure _toFailure(AppException e) => switch (e) {
        NetworkException(:final message) => NetworkFailure(message),
        UnauthorizedException(:final message) => UnauthorizedFailure(message),
        ServerException(:final message, :final statusCode) =>
          ServerFailure(message, statusCode: statusCode),
        CacheException(:final message) => CacheFailure(message),
      };

  // Adapt this if your domain entity diverges from the data model shape.
  Future<dynamic> _toModel(ExampleEntity entity) async => entity;
}
