part of 'record_bloc.dart';

@immutable
sealed class RecordState extends Equatable {
  const RecordState();

  @override
  List<Object?> get props => [];
}

final class RecordInitial extends RecordState {
  const RecordInitial();
}

final class RecordLoading extends RecordState {
  const RecordLoading();
}

final class RecordLoaded extends RecordState {
  const RecordLoaded({required this.records});

  final List<PipelineRecord> records;

  @override
  List<Object?> get props => [records];
}

final class RecordError extends RecordState {
  const RecordError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
