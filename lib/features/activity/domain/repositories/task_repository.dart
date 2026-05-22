import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';

/// Repository for activities (tasks, calls, meetings).
/// Uses the unified /api/activities endpoint.
abstract interface class TaskRepository {
  /// Fetches all activities regardless of type.
  Future<Result<List<Activity>, AppFailure>> getActivities();

  /// Fetches only task-type activities.
  Future<Result<List<Activity>, AppFailure>> getTasks();
  Future<Result<Activity, AppFailure>> getTask(String id);
  Future<Result<Activity, AppFailure>> createTask(Activity task);
  Future<Result<Activity, AppFailure>> updateTask(Activity task);
  Future<Result<void, AppFailure>> deleteTask(String id);
}
