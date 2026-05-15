import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';

// ignore: one_member_abstracts
abstract interface class TimelineRepository {
  Future<Result<List<TimelineEntry>, AppFailure>> getTimeline({
    required String entityType,
    required String entityId,
  });
}
