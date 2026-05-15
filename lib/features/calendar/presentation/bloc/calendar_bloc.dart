import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────────────────

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

// ── State ───────────────────────────────────────────────────────────────

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

// ── Bloc ────────────────────────────────────────────────────────────────

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarState> {
  CalendarBloc({required CalendarRepository repository})
      : _repository = repository,
        super(const CalendarInitial()) {
    on<CalendarLoadRequested>(_onLoad, transformer: restartable());
    on<CalendarEventCreateRequested>(_onCreate, transformer: droppable());
  }

  final CalendarRepository _repository;

  Future<void> _onLoad(
    CalendarLoadRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());
    final result = await _repository.getEvents();
    switch (result) {
      case Success(:final data):
        emit(CalendarLoaded(events: data));
      case Failure(:final error):
        emit(CalendarError(failure: error));
    }
  }

  Future<void> _onCreate(
    CalendarEventCreateRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());
    final result = await _repository.createEvent(event.event);
    switch (result) {
      case Success():
        final listResult = await _repository.getEvents();
        switch (listResult) {
          case Success(:final data):
            emit(CalendarLoaded(events: data));
          case Failure(:final error):
            emit(CalendarError(failure: error));
        }
      case Failure(:final error):
        emit(CalendarError(failure: error));
    }
  }
}
