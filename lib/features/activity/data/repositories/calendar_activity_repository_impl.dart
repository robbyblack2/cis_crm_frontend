import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';

class CalendarActivityRepositoryImpl implements CalendarActivityRepository {
  const CalendarActivityRepositoryImpl({
    required ActivityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ActivityRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Activity>, AppFailure>> getActivities({
    String? activityType,
    String? statusId,
    String? phase,
    String? assigneeId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final activities = await _remoteDataSource.getActivities(
        activityType: activityType,
        statusId: statusId,
        phase: phase,
        assigneeId: assigneeId,
        from: from,
        to: to,
        page: page,
        perPage: perPage,
      );
      return Success(activities);
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
