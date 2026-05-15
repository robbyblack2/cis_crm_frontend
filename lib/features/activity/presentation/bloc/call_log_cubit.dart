import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ───────────────────────────────────────────────────────────────

@immutable
sealed class CallLogState extends Equatable {
  const CallLogState();

  @override
  List<Object?> get props => [];
}

final class CallLogInitial extends CallLogState {
  const CallLogInitial();
}

final class CallLogLoading extends CallLogState {
  const CallLogLoading();
}

final class CallLogLoaded extends CallLogState {
  const CallLogLoaded({required this.callLogs});

  final List<CallLog> callLogs;

  @override
  List<Object?> get props => [callLogs];
}

final class CallLogError extends CallLogState {
  const CallLogError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────

class CallLogCubit extends Cubit<CallLogState> {
  CallLogCubit({required CallLogRepository callLogRepository})
      : _repository = callLogRepository,
        super(const CallLogInitial());

  final CallLogRepository _repository;

  Future<void> loadCallLogs() async {
    emit(const CallLogLoading());
    final result = await _repository.getCallLogs();
    switch (result) {
      case Success(:final data):
        emit(CallLogLoaded(callLogs: data));
      case Failure(:final error):
        emit(CallLogError(message: error.message));
    }
  }

  Future<void> logCall(CallLog log) async {
    emit(const CallLogLoading());
    final result = await _repository.logCall(log);
    switch (result) {
      case Success():
        final listResult = await _repository.getCallLogs();
        switch (listResult) {
          case Success(:final data):
            emit(CallLogLoaded(callLogs: data));
          case Failure(:final error):
            emit(CallLogError(message: error.message));
        }
      case Failure(:final error):
        emit(CallLogError(message: error.message));
    }
  }
}
