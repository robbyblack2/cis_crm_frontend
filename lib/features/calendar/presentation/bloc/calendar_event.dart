part of 'calendar_bloc.dart';

@immutable
sealed class CalendarBlocEvent extends Equatable {
  const CalendarBlocEvent();

  @override
  List<Object?> get props => [];
}

final class CalendarLoadRequested extends CalendarBlocEvent {
  const CalendarLoadRequested();
}

final class CalendarEventCreateRequested extends CalendarBlocEvent {
  const CalendarEventCreateRequested({required this.event});

  final CalendarEvent event;

  @override
  List<Object?> get props => [event];
}
