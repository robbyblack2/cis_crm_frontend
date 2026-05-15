import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';

abstract interface class TaskRepository {
  Future<Result<List<CrmTask>, AppFailure>> getTasks();
  Future<Result<CrmTask, AppFailure>> getTask(String id);
  Future<Result<CrmTask, AppFailure>> createTask(CrmTask task);
  Future<Result<CrmTask, AppFailure>> updateTask(CrmTask task);
  Future<Result<void, AppFailure>> deleteTask(String id);
}
