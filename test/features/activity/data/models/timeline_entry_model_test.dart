import 'package:cis_crm/features/activity/data/models/timeline_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimelineEntryModel.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'tl-1',
        'entity_type': 'record',
        'entity_id': 'rec-1',
        'event_type': 'stage_change',
        'actor_type': 'human',
        'actor_id': 'user-1',
        'summary': 'Moved to Negotiation',
        'detail': {'from_stage': 'Discovery', 'to_stage': 'Negotiation'},
        'created_at': '2026-05-20T10:00:00Z',
      };

      final model = TimelineEntryModel.fromJson(json);

      expect(model.id, 'tl-1');
      expect(model.entityType, 'record');
      expect(model.entityId, 'rec-1');
      expect(model.eventType, 'stage_change');
      expect(model.actorType, 'human');
      expect(model.actorId, 'user-1');
      expect(model.summary, 'Moved to Negotiation');
      expect(model.createdAt, DateTime.utc(2026, 5, 20, 10));
    });

    test('handles null actor_id for system events', () {
      final json = {
        'id': 'tl-2',
        'entity_type': 'record',
        'entity_id': 'rec-1',
        'event_type': 'automation',
        'actor_type': 'system',
        'actor_id': null,
        'summary': 'Auto-assigned',
        'created_at': '2026-05-20T10:00:00Z',
      };

      final model = TimelineEntryModel.fromJson(json);

      expect(model.actorId, '');
      expect(model.actorType, 'system');
    });

    test('handles integer IDs', () {
      final json = {
        'id': 42,
        'entity_type': 'contact',
        'entity_id': 99,
        'event_type': 'note',
        'actor_type': 'human',
        'actor_id': 7,
        'summary': 'Added note',
        'created_at': '2026-05-20T10:00:00Z',
      };

      final model = TimelineEntryModel.fromJson(json);

      expect(model.id, '42');
      expect(model.entityId, '99');
      expect(model.actorId, '7');
    });

    test('handles missing summary gracefully', () {
      final json = {
        'id': 'tl-3',
        'entity_type': 'record',
        'entity_id': 'rec-1',
        'event_type': 'field_change',
        'actor_type': 'human',
        'actor_id': 'user-1',
        'summary': null,
        'created_at': '2026-05-20T10:00:00Z',
      };

      final model = TimelineEntryModel.fromJson(json);

      expect(model.summary, '');
    });
  });
}
