import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'call_log_state.dart';

class CallLogCubit extends Cubit<CallLogState> {
  CallLogCubit({required CallLogRepository callLogRepository})
      : _callLogRepository = callLogRepository,
        super(const CallLogInitial());

  final CallLogRepository _callLogRepository;

  Future<void> loadCallLogs() async {
    emit(const CallLogLoading());
    final result = await _callLogRepository.getCallLogs();
    switch (result) {
      case Success(data: final logs):
        emit(CallLogLoaded(callLogs: logs));
      case Failure(error: final failure):
        emit(CallLogError(message: failure.message));
    }
  }

  Future<void> logCall(CallLog callLog) async {
    emit(const CallLogLoading());
    final result = await _callLogRepository.logCall(callLog);
    switch (result) {
      case Success():
        final loadResult = await _callLogRepository.getCallLogs();
        switch (loadResult) {
          case Success(data: final logs):
            emit(CallLogLoaded(callLogs: logs));
          case Failure(error: final failure):
            emit(CallLogError(message: failure.message));
        }
      case Failure(error: final failure):
        emit(CallLogError(message: failure.message));
    }
  }
}
