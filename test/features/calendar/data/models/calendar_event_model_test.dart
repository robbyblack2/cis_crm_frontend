import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarEventModel.fromJson', () {
    test('parses meeting_url and conference_provider', () {
      final json = {
        'id': 'ev-1',
        'title': 'Standup',
        'start_time': '2026-05-21T09:00:00Z',
        'end_time': '2026-05-21T09:30:00Z',
        'created_at': '2026-05-20T10:00:00Z',
        'meeting_url': 'https://meet.google.com/abc-defg-hij',
        'conference_provider': 'Google Meet',
        'conference_data': {'entry_point': 'https://meet.google.com/abc'},
      };

      final model = CalendarEventModel.fromJson(json);

      expect(model.meetingLink, 'https://meet.google.com/abc-defg-hij');
      expect(model.conferenceProvider, 'Google Meet');
      expect(model.conferenceData, isNotNull);
      expect(model.conferenceData!['entry_point'],
          'https://meet.google.com/abc');
    });

    test('falls back to meeting_link if meeting_url is absent', () {
      final json = {
        'id': 'ev-2',
        'title': 'Call',
        'start_time': '2026-05-21T10:00:00Z',
        'end_time': '2026-05-21T10:30:00Z',
        'created_at': '2026-05-20T10:00:00Z',
        'meeting_link': 'https://zoom.us/j/123',
      };

      final model = CalendarEventModel.fromJson(json);
      expect(model.meetingLink, 'https://zoom.us/j/123');
    });

    test('meeting fields are null when absent', () {
      final json = {
        'id': 'ev-3',
        'title': 'Lunch',
        'start_time': '2026-05-21T12:00:00Z',
        'end_time': '2026-05-21T13:00:00Z',
        'created_at': '2026-05-20T10:00:00Z',
      };

      final model = CalendarEventModel.fromJson(json);

      expect(model.meetingLink, isNull);
      expect(model.conferenceProvider, isNull);
      expect(model.conferenceData, isNull);
    });

    test('parses location and google_event_id', () {
      final json = {
        'id': 'ev-4',
        'title': 'Offsite',
        'start_time': '2026-05-22T09:00:00Z',
        'end_time': '2026-05-22T17:00:00Z',
        'created_at': '2026-05-20T10:00:00Z',
        'location': 'Conference Room B',
        'google_event_id': 'gev-123',
      };

      final model = CalendarEventModel.fromJson(json);

      expect(model.location, 'Conference Room B');
      expect(model.googleEventId, 'gev-123');
    });
  });

  group('CalendarEvent.hasMeeting', () {
    test('returns true when meetingLink is set', () {
      final model = CalendarEventModel(
        id: '1',
        title: 'T',
        start: DateTime.utc(2026),
        end: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
        meetingLink: 'https://meet.google.com/abc',
      );
      expect(model.hasMeeting, isTrue);
    });

    test('returns false when meetingLink is null', () {
      final model = CalendarEventModel(
        id: '1',
        title: 'T',
        start: DateTime.utc(2026),
        end: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
      );
      expect(model.hasMeeting, isFalse);
    });

    test('returns false when meetingLink is empty string', () {
      final model = CalendarEventModel(
        id: '1',
        title: 'T',
        start: DateTime.utc(2026),
        end: DateTime.utc(2026),
        createdAt: DateTime.utc(2026),
        meetingLink: '',
      );
      expect(model.hasMeeting, isFalse);
    });
  });

  group('CalendarEventModel.toJson', () {
    test('outputs meeting_url key', () {
      final model = CalendarEventModel(
        id: '1',
        title: 'Meeting',
        start: DateTime.utc(2026, 5, 21, 9),
        end: DateTime.utc(2026, 5, 21, 10),
        createdAt: DateTime.utc(2026),
        meetingLink: 'https://meet.google.com/xyz',
      );

      final json = model.toJson();
      expect(json['meeting_url'], 'https://meet.google.com/xyz');
      expect(json.containsKey('meeting_link'), isFalse);
    });
  });
}
