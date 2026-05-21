import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';

/// Repository for task-type activities.
/// Uses the unified /api/activities endpoint with activity_type=task.
abstract interface class TaskRepository {
  Future<Result<List<Activity>, AppFailure>> getTasks();
  Future<Result<Activity, AppFailure>> getTask(String id);
  Future<Result<Activity, AppFailure>> createTask(Activity task);
  Future<Result<Activity, AppFailure>> updateTask(Activity task);
  Future<Result<void, AppFailure>> deleteTask(String id);
}
