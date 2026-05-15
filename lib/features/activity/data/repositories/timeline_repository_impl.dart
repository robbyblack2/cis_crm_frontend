import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';
import 'package:cis_crm/features/activity/domain/repositories/timeline_repository.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  const TimelineRepositoryImpl({
    required ActivityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ActivityRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TimelineEntry>, AppFailure>> getTimeline({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final entries = await _remoteDataSource.getTimeline(
        entityType: entityType,
        entityId: entityId,
      );
      return Success(entries);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
