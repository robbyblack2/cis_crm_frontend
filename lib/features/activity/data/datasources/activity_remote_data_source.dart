import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/data/models/timeline_entry_model.dart';

abstract interface class ActivityRemoteDataSource {
  Future<List<ActivityModel>> getActivities({
    String? activityType,
    String? statusId,
    String? phase,
    String? assigneeId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 25,
  });

  Future<ActivityModel> getActivity(String id);
  Future<ActivityModel> createActivity(ActivityModel activity);
  Future<ActivityModel> updateActivity(ActivityModel activity);
  Future<void> deleteActivity(String id);

  Future<List<TimelineEntryModel>> getTimeline({
    required String entityType,
    required String entityId,
  });
}
