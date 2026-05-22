import 'package:cis_crm/features/email/data/models/email_template_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailTemplateModel.fromJson', () {
    test('parses subject_template and body_template correctly', () {
      final json = {
        'id': 'tpl-1',
        'name': 'Follow-up',
        'subject_template': 'Hi {{contact_name}}',
        'body_template': '<p>Thanks for your time</p>',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T12:00:00Z',
      };

      final model = EmailTemplateModel.fromJson(json);

      expect(model.id, 'tpl-1');
      expect(model.name, 'Follow-up');
      expect(model.subjectTemplate, 'Hi {{contact_name}}');
      expect(model.bodyTemplate, '<p>Thanks for your time</p>');
    });

    test('parses variables field when present', () {
      final json = {
        'id': 'tpl-2',
        'name': 'Quote',
        'subject_template': 'Your quote',
        'body_template': 'See attached',
        'variables': {'contact_name': 'string', 'amount': 'number'},
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = EmailTemplateModel.fromJson(json);

      expect(model.variables, isNotNull);
      expect((model.variables as Map)['contact_name'], 'string');
    });

    test('parses created_by field when present', () {
      final json = {
        'id': 'tpl-3',
        'name': 'Intro',
        'subject_template': 'Hello',
        'body_template': 'World',
        'created_by': 'user-123',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = EmailTemplateModel.fromJson(json);
      expect(model.createdBy, 'user-123');
    });

    test('variables and created_by are null when absent', () {
      final json = {
        'id': 'tpl-4',
        'name': 'Simple',
        'subject_template': 'Hi',
        'body_template': 'Bye',
        'created_at': '2026-05-20T10:00:00Z',
        'updated_at': '2026-05-20T10:00:00Z',
      };

      final model = EmailTemplateModel.fromJson(json);

      expect(model.variables, isNull);
      expect(model.createdBy, isNull);
    });
  });

  group('EmailTemplateModel.toJson', () {
    test('serializes to subject_template and body_template keys', () {
      final model = EmailTemplateModel(
        id: 'tpl-1',
        name: 'Test',
        subjectTemplate: 'Subject here',
        bodyTemplate: 'Body here',
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
      );

      final json = model.toJson();

      expect(json['subject_template'], 'Subject here');
      expect(json['body_template'], 'Body here');
      expect(json['name'], 'Test');
      // Should NOT have old keys
      expect(json.containsKey('subject'), isFalse);
      expect(json.containsKey('body'), isFalse);
    });

    test('includes variables and created_by in output', () {
      final model = EmailTemplateModel(
        id: 'tpl-2',
        name: 'V',
        subjectTemplate: 'S',
        bodyTemplate: 'B',
        variables: {'key': 'val'},
        createdBy: 'user-1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      final json = model.toJson();

      expect(json['variables'], {'key': 'val'});
      expect(json['created_by'], 'user-1');
    });
  });
}
