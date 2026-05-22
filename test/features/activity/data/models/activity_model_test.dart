import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityModel.fromJson', () {
    test('parses all required fields correctly', () {
      final json = {
        'id': 'act-1',
        'activity_type': 'task',
        'title': 'Follow up with Jane',
        'status_id': 'status-1',
        'status_name': 'To Do',
        'status_phase': 'open',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T12:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.id, 'act-1');
      expect(model.activityType, ActivityType.task);
      expect(model.title, 'Follow up with Jane');
      expect(model.statusId, 'status-1');
      expect(model.statusName, 'To Do');
      expect(model.statusPhase, 'open');
      expect(model.createdAt, DateTime.utc(2026, 5, 20, 10));
      expect(model.updatedAt, DateTime.utc(2026, 5, 20, 12));
    });

    test('parses optional fields when present', () {
      final json = {
        'id': 'act-2',
        'activity_type': 'call',
        'title': 'Discovery call',
        'status_id': 'status-2',
        'status_name': 'Planned',
        'status_phase': 'open',
        'description': 'Discuss pricing',
        'priority': 'high',
        'assignee_id': 'user-1',
        'subtype_id': 'sub-1',
        'subtype_name': 'Discovery',
        'due_date': '2026-06-01',
        'due_time': '14:00',
        'completed_at': '2026-06-01T15:00:00Z',
        'created_by': 'user-2',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T12:00:00Z',
        'data': {'direction': 'outbound'},
        'links': [
          {
            'id': 'link-1',
            'entity_type': 'contact',
            'entity_id': 'contact-1',
          },
        ],
      };

      final model = ActivityModel.fromJson(json);

      expect(model.activityType, ActivityType.call);
      expect(model.description, 'Discuss pricing');
      expect(model.priority, ActivityPriority.high);
      expect(model.assigneeId, 'user-1');
      expect(model.subtypeId, 'sub-1');
      expect(model.subtypeName, 'Discovery');
      expect(model.dueDate, '2026-06-01');
      expect(model.dueTime, '14:00');
      expect(model.completedAt, DateTime.utc(2026, 6, 1, 15));
      expect(model.createdBy, 'user-2');
      expect(model.data, {'direction': 'outbound'});
      expect(model.links, hasLength(1));
      expect(model.links.first.entityType, 'contact');
      expect(model.links.first.entityId, 'contact-1');
      expect(model.links.first.linkId, 'link-1');
    });

    test('defaults missing optional fields to null/empty', () {
      final json = {
        'id': 'act-3',
        'activity_type': 'meeting',
        'title': 'Standup',
        'status_id': 'status-3',
        'status_name': 'Planned',
        'status_phase': 'open',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.description, isNull);
      expect(model.priority, isNull);
      expect(model.assigneeId, isNull);
      expect(model.subtypeId, isNull);
      expect(model.subtypeName, isNull);
      expect(model.dueDate, isNull);
      expect(model.dueTime, isNull);
      expect(model.completedAt, isNull);
      expect(model.createdBy, isNull);
      expect(model.data, isEmpty);
      expect(model.links, isEmpty);
    });

    test('defaults unknown activity_type to task', () {
      final json = {
        'id': 'act-4',
        'activity_type': 'unknown_type',
        'title': 'Test',
        'status_id': '',
        'status_name': '',
        'status_phase': 'open',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);
      expect(model.activityType, ActivityType.task);
    });

    test('defaults missing status_phase to open', () {
      final json = {
        'id': 'act-5',
        'activity_type': 'task',
        'title': 'Test',
        'status_id': 'x',
        'status_name': 'x',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);
      expect(model.statusPhase, 'open');
    });
  });

  group('ActivityModel.toJson', () {
    test('serializes required fields with correct keys', () {
      final model = ActivityModel(
        id: 'act-1',
        activityType: ActivityType.task,
        title: 'Test task',
        statusId: 'status-1',
        statusName: 'To Do',
        statusPhase: 'open',
        createdAt: _epoch,
        updatedAt: _epoch,
      );

      final json = model.toJson();

      expect(json['activity_type'], 'task');
      expect(json['title'], 'Test task');
      expect(json['status_id'], 'status-1');
    });

    test('includes optional fields only when set', () {
      final model = ActivityModel(
        id: 'act-1',
        activityType: ActivityType.call,
        title: 'Call',
        statusId: 'status-1',
        statusName: '',
        statusPhase: 'open',
        createdAt: _epoch,
        updatedAt: _epoch,
        description: 'Notes here',
        priority: ActivityPriority.medium,
        assigneeId: 'user-1',
        subtypeId: 'sub-1',
        dueDate: '2026-06-01',
        dueTime: '10:00',
      );

      final json = model.toJson();

      expect(json['description'], 'Notes here');
      expect(json['priority'], 'medium');
      expect(json['assignee_id'], 'user-1');
      expect(json['subtype_id'], 'sub-1');
      expect(json['due_date'], '2026-06-01');
      expect(json['due_time'], '10:00');
    });

    test('omits null optional fields', () {
      final model = ActivityModel(
        id: 'act-1',
        activityType: ActivityType.meeting,
        title: 'Meeting',
        statusId: 'status-1',
        statusName: '',
        statusPhase: 'open',
        createdAt: _epoch,
        updatedAt: _epoch,
      );

      final json = model.toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('priority'), isFalse);
      expect(json.containsKey('assignee_id'), isFalse);
      expect(json.containsKey('subtype_id'), isFalse);
      expect(json.containsKey('due_date'), isFalse);
      expect(json.containsKey('due_time'), isFalse);
    });

    test('serializes links correctly', () {
      final model = ActivityModel(
        id: 'act-1',
        activityType: ActivityType.task,
        title: 'Task',
        statusId: 'status-1',
        statusName: '',
        statusPhase: 'open',
        createdAt: _epoch,
        updatedAt: _epoch,
        links: [
          ActivityLink(entityType: 'contact', entityId: 'c-1'),
          ActivityLink(entityType: 'record', entityId: 'r-1'),
        ],
      );

      final json = model.toJson();
      final links = json['links'] as List;

      expect(links, hasLength(2));
      expect(links[0], {'entity_type': 'contact', 'entity_id': 'c-1'});
      expect(links[1], {'entity_type': 'record', 'entity_id': 'r-1'});
    });
  });

  group('ActivityModel.fromJson — nested backend format', () {
    test('parses nested status object for status_name and status_phase', () {
      final json = {
        'id': 'act-10',
        'activity_type': 'task',
        'title': 'Nested status test',
        'status_id': 'status-1',
        'status': {'id': 'status-1', 'name': 'To Do', 'phase': 'open'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.statusName, 'To Do');
      expect(model.statusPhase, 'open');
    });

    test('parses nested subtype object for subtype_name', () {
      final json = {
        'id': 'act-11',
        'activity_type': 'task',
        'title': 'Nested subtype test',
        'status_id': 'status-1',
        'status': {'id': 'status-1', 'name': 'To Do', 'phase': 'open'},
        'subtype_id': 'sub-1',
        'subtype': {'id': 'sub-1', 'name': 'Follow-up'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.subtypeId, 'sub-1');
      expect(model.subtypeName, 'Follow-up');
    });

    test('handles integer IDs by coercing to string', () {
      final json = {
        'id': 'act-12',
        'activity_type': 'call',
        'title': 'Int ID test',
        'status_id': 42,
        'status': {'id': 42, 'name': 'Planned', 'phase': 'open'},
        'subtype_id': 7,
        'subtype': {'id': 7, 'name': 'Discovery'},
        'assignee_id': 99,
        'created_by': 5,
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.statusId, '42');
      expect(model.statusName, 'Planned');
      expect(model.statusPhase, 'open');
      expect(model.subtypeId, '7');
      expect(model.subtypeName, 'Discovery');
      expect(model.assigneeId, '99');
      expect(model.createdBy, '5');
    });

    test('prefers flat status_name/status_phase when both flat and nested exist', () {
      final json = {
        'id': 'act-13',
        'activity_type': 'task',
        'title': 'Both formats',
        'status_id': 'status-1',
        'status_name': 'FlatName',
        'status_phase': 'closed',
        'status': {'id': 'status-1', 'name': 'NestedName', 'phase': 'open'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      // Flat fields take precedence (backwards compat)
      expect(model.statusName, 'FlatName');
      expect(model.statusPhase, 'closed');
    });

    test('parses meeting fields from nested backend format', () {
      final json = {
        'id': 'act-14',
        'activity_type': 'meeting',
        'title': 'Demo Call',
        'status_id': 5,
        'status': {'id': 5, 'name': 'Planned', 'phase': 'open'},
        'start_time': '2026-05-28T14:00:00Z',
        'end_time': '2026-05-28T15:00:00Z',
        'meeting_url': 'https://meet.google.com/abc',
        'conference_provider': 'google_meet',
        'calendar_provider': 'google',
        'calendar_event_id': 'gcal-123',
        'attendees': [
          {'email': 'john@acme.com', 'name': 'John', 'rsvp_status': 'accepted'},
        ],
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = ActivityModel.fromJson(json);

      expect(model.activityType, ActivityType.meeting);
      expect(model.statusId, '5');
      expect(model.statusName, 'Planned');
      expect(model.startTime, DateTime.utc(2026, 5, 28, 14));
      expect(model.endTime, DateTime.utc(2026, 5, 28, 15));
      expect(model.meetingUrl, 'https://meet.google.com/abc');
      expect(model.conferenceProvider, 'google_meet');
      expect(model.calendarProvider, 'google');
      expect(model.calendarEventId, 'gcal-123');
      expect(model.attendees, hasLength(1));
    });
  });

  group('ActivityModel.fromJson — meeting URL extraction from data', () {
    test('extracts hangout_link from data when meeting_url is absent', () {
      final json = {
        'id': 'act-20',
        'activity_type': 'meeting',
        'title': 'Demo Call',
        'status_id': '1',
        'status': {'id': '1', 'name': 'Planned', 'phase': 'open'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
        'data': {'hangout_link': 'https://meet.google.com/abc-defg-hij'},
      };

      final model = ActivityModel.fromJson(json);
      expect(model.meetingUrl, 'https://meet.google.com/abc-defg-hij');
      expect(model.conferenceProvider, 'google_meet');
    });

    test('extracts html_link from data as fallback', () {
      final json = {
        'id': 'act-21',
        'activity_type': 'meeting',
        'title': 'Zoom Call',
        'status_id': '1',
        'status': {'id': '1', 'name': 'Planned', 'phase': 'open'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
        'data': {'html_link': 'https://zoom.us/j/12345'},
      };

      final model = ActivityModel.fromJson(json);
      expect(model.meetingUrl, 'https://zoom.us/j/12345');
      expect(model.conferenceProvider, 'zoom');
    });

    test('prefers top-level meeting_url over data field', () {
      final json = {
        'id': 'act-22',
        'activity_type': 'meeting',
        'title': 'Test',
        'status_id': '1',
        'status': {'id': '1', 'name': 'Planned', 'phase': 'open'},
        'meeting_url': 'https://meet.google.com/top-level',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
        'data': {'hangout_link': 'https://meet.google.com/data-level'},
      };

      final model = ActivityModel.fromJson(json);
      expect(model.meetingUrl, 'https://meet.google.com/top-level');
    });

    test('extracts from conference_data.entry_points', () {
      final json = {
        'id': 'act-23',
        'activity_type': 'meeting',
        'title': 'Conf Data',
        'status_id': '1',
        'status': {'id': '1', 'name': 'Planned', 'phase': 'open'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
        'data': {
          'conference_data': {
            'entry_points': [
              {'uri': 'https://meet.google.com/nested-link'},
            ],
          },
        },
      };

      final model = ActivityModel.fromJson(json);
      expect(model.meetingUrl, 'https://meet.google.com/nested-link');
    });
  });

  group('Activity.isCompleted', () {
    test('returns true when statusPhase is closed', () {
      final activity = ActivityModel(
        id: '1',
        activityType: ActivityType.task,
        title: 'Done task',
        statusId: 's',
        statusName: 'Done',
        statusPhase: 'closed',
        createdAt: _epoch,
        updatedAt: _epoch,
      );
      expect(activity.isCompleted, isTrue);
    });

    test('returns false when statusPhase is open', () {
      final activity = ActivityModel(
        id: '1',
        activityType: ActivityType.task,
        title: 'Open task',
        statusId: 's',
        statusName: 'To Do',
        statusPhase: 'open',
        createdAt: _epoch,
        updatedAt: _epoch,
      );
      expect(activity.isCompleted, isFalse);
    });
  });
}

final _epoch = DateTime.utc(2026);
