import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';

/// Repository for call-type activities.
/// Uses the unified /api/activities endpoint with activity_type=call.
abstract interface class CallLogRepository {
  Future<Result<List<Activity>, AppFailure>> getCallLogs();
  Future<Result<Activity, AppFailure>> logCall(Activity callLog);
}
