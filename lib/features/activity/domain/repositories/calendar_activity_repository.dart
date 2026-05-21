import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';

abstract interface class CalendarActivityRepository {
  Future<Result<List<Activity>, AppFailure>> getActivities({
    required String from,
    required String to,
  });
}
