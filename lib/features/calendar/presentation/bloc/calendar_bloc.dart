import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarState> {
  CalendarBloc({required CalendarRepository repository})
      : _repository = repository,
        super(const CalendarInitial()) {
    on<CalendarLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<CalendarEventCreateRequested>(
      _onCreateRequested,
      transformer: droppable(),
    );
  }

  final CalendarRepository _repository;

  Future<void> _onLoadRequested(
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

  Future<void> _onCreateRequested(
    CalendarEventCreateRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());
    final result = await _repository.createEvent(event.event);
    switch (result) {
      case Success():
        final loadResult = await _repository.getEvents();
        switch (loadResult) {
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
