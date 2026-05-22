import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/datasources/activities_data_source.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';

class CalendarActivityRepositoryImpl implements CalendarActivityRepository {
  const CalendarActivityRepositoryImpl({
    required ActivitiesDataSource dataSource,
  }) : _dataSource = dataSource;

  final ActivitiesDataSource _dataSource;

  @override
  Future<Result<List<Activity>, AppFailure>> getActivities({
    String? activityType,
    String? statusId,
    String? phase,
    String? assigneeId,
    String? from,
    String? to,
    String? startFrom,
    String? startTo,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final activities = await _dataSource.getActivities(
        type: activityType != null
            ? ActivityType.values.firstWhere(
                (t) => t.name == activityType,
                orElse: () => ActivityType.task,
              )
            : null,
        statusId: statusId,
        phase: phase,
        assigneeId: assigneeId,
        from: from,
        to: to,
        startFrom: startFrom,
        startTo: startTo,
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
