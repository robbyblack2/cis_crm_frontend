part of 'calendar_bloc.dart';

@immutable
sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

final class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

final class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

final class CalendarLoaded extends CalendarState {
  const CalendarLoaded({required this.events});

  final List<CalendarEvent> events;

  @override
  List<Object?> get props => [events];
}

final class CalendarError extends CalendarState {
  const CalendarError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
