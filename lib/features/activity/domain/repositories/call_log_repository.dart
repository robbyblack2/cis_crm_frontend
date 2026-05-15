import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';

abstract interface class CallLogRepository {
  Future<Result<List<CallLog>, AppFailure>> getCallLogs();
  Future<Result<CallLog, AppFailure>> logCall(CallLog callLog);
}
