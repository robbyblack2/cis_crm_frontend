import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/data/models/call_log_model.dart';
import 'package:cis_crm/features/activity/data/models/crm_task_model.dart';
import 'package:cis_crm/features/activity/data/models/timeline_entry_model.dart';

abstract interface class ActivityRemoteDataSource {
  Future<List<ActivityModel>> getActivities({
    required String from,
    required String to,
    int perPage = 100,
  });

  Future<List<CrmTaskModel>> getTasks();
  Future<CrmTaskModel> getTask(String id);
  Future<CrmTaskModel> createTask(CrmTaskModel task);
  Future<CrmTaskModel> updateTask(CrmTaskModel task);
  Future<void> deleteTask(String id);

  Future<List<CallLogModel>> getCallLogs();
  Future<CallLogModel> logCall(CallLogModel callLog);

  Future<List<TimelineEntryModel>> getTimeline({
    required String entityType,
    required String entityId,
  });
}
