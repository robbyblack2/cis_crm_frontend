import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';

abstract interface class CalendarActivityRepository {
  Future<Result<List<Activity>, AppFailure>> getActivities({
    String? activityType,
    String? statusId,
    String? phase,
    String? assigneeId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 25,
  });
}
