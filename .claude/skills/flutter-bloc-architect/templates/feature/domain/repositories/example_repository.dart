import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/example_entity.dart';

/// Abstract repository contract for the `example` feature.
///
/// The bloc depends on this — never on the impl. Tests inject mocks of
/// this class via `mocktail`. The `data/` layer provides the concrete
/// implementation.
abstract interface class ExampleRepository {
  Future<Result<List<ExampleEntity>, AppFailure>> getAll();

  Future<Result<ExampleEntity, AppFailure>> getById(String id);

  Future<Result<ExampleEntity, AppFailure>> create(ExampleEntity entity);

  Future<Result<void, AppFailure>> delete(String id);
}
