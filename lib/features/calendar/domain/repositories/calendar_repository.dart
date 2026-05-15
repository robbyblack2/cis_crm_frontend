import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';

abstract interface class CalendarRepository {
  Future<Result<List<CalendarEvent>, AppFailure>> getEvents();
  Future<Result<CalendarEvent, AppFailure>> createEvent(CalendarEvent event);
  Future<Result<CalendarEvent, AppFailure>> updateEvent(CalendarEvent event);
  Future<Result<void, AppFailure>> deleteEvent(String id);
}
