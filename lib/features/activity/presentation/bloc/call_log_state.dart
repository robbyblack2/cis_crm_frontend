part of 'call_log_cubit.dart';

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
