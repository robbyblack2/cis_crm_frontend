import 'package:flutter_test/flutter_test.dart';

// These are unit tests for the template variable resolution and placeholder
// detection logic used in EmailComposePage. We extract the pure logic to test
// it without widget dependencies.

/// Resolves template variables in a string.
String resolveVars(String template, Map<String, String> vars) {
  var result = template;
  for (final entry in vars.entries) {
    result = result.replaceAll('{{${entry.key}}}', entry.value);
  }
  return result;
}

/// Finds all unresolved {{...}} placeholders in a string.
List<String> findUnresolved(String text) {
  final pattern = RegExp(r'\{\{[^}]+\}\}');
  return pattern.allMatches(text).map((m) => m.group(0)!).toSet().toList();
}

/// Builds template variables from recipient and user context.
Map<String, String> buildTemplateVars({
  String? recipientEmail,
  String? recipientName,
  String? companyName,
  String? userName,
  String? userEmail,
  String? recordTitle,
  String? date,
}) {
  final vars = <String, String>{};
  if (recipientEmail != null) vars['contact_email'] = recipientEmail;
  if (recipientName != null) {
    vars['contact_name'] = recipientName;
    final parts = recipientName.split(' ');
    if (parts.isNotEmpty) vars['contact_first_name'] = parts.first;
  }
  if (companyName != null) vars['company_name'] = companyName;
  if (userName != null) vars['user_name'] = userName;
  if (userEmail != null) vars['user_email'] = userEmail;
  if (recordTitle != null) vars['record_title'] = recordTitle;
  if (date != null) vars['date'] = date;
  return vars;
}

void main() {
  group('resolveVars', () {
    test('resolves contact_name variable', () {
      final result = resolveVars(
        'Hi {{contact_name}}, welcome!',
        {'contact_name': 'Jane Doe'},
      );
      expect(result, 'Hi Jane Doe, welcome!');
    });

    test('resolves multiple variables', () {
      final result = resolveVars(
        'Hi {{contact_first_name}}, this is {{user_name}} from {{company_name}}.',
        {
          'contact_first_name': 'Jane',
          'user_name': 'John Smith',
          'company_name': 'Acme Corp',
        },
      );
      expect(result, 'Hi Jane, this is John Smith from Acme Corp.');
    });

    test('leaves unresolved variables intact', () {
      final result = resolveVars(
        'Hi {{contact_name}}, re: {{record_title}}',
        {'contact_name': 'Jane Doe'},
      );
      expect(result, 'Hi Jane Doe, re: {{record_title}}');
    });

    test('handles empty vars map', () {
      final result = resolveVars('Hi {{contact_name}}!', {});
      expect(result, 'Hi {{contact_name}}!');
    });

    test('handles template with no variables', () {
      final result = resolveVars(
        'Hello, plain text here.',
        {'contact_name': 'Jane'},
      );
      expect(result, 'Hello, plain text here.');
    });

    test('resolves same variable appearing multiple times', () {
      final result = resolveVars(
        'Dear {{contact_name}}, as discussed with {{contact_name}}...',
        {'contact_name': 'Jane Doe'},
      );
      expect(result, 'Dear Jane Doe, as discussed with Jane Doe...');
    });

    test('resolves contact_email', () {
      final result = resolveVars(
        'Sending to {{contact_email}}',
        {'contact_email': 'jane@acme.com'},
      );
      expect(result, 'Sending to jane@acme.com');
    });

    test('resolves date variable', () {
      final result = resolveVars(
        'As of {{date}}',
        {'date': 'May 21, 2026'},
      );
      expect(result, 'As of May 21, 2026');
    });

    test('resolves user_email', () {
      final result = resolveVars(
        'Reply to {{user_email}}',
        {'user_email': 'john@crm.com'},
      );
      expect(result, 'Reply to john@crm.com');
    });

    test('resolves record_title', () {
      final result = resolveVars(
        'Re: {{record_title}}',
        {'record_title': 'Fix login timeout'},
      );
      expect(result, 'Re: Fix login timeout');
    });
  });

  group('findUnresolved', () {
    test('finds single unresolved placeholder', () {
      final result = findUnresolved('Hi {{contact_name}}!');
      expect(result, ['{{contact_name}}']);
    });

    test('finds multiple unresolved placeholders', () {
      final result = findUnresolved(
        'Hi {{contact_name}}, re: {{record_title}} on {{date}}',
      );
      expect(result, unorderedEquals([
        '{{contact_name}}',
        '{{record_title}}',
        '{{date}}',
      ]));
    });

    test('returns empty list when no placeholders', () {
      final result = findUnresolved('Hello, plain text.');
      expect(result, isEmpty);
    });

    test('returns empty list for fully resolved text', () {
      final result = findUnresolved('Hi Jane Doe, welcome!');
      expect(result, isEmpty);
    });

    test('deduplicates repeated placeholders', () {
      final result = findUnresolved(
        '{{name}} and {{name}} again',
      );
      expect(result, ['{{name}}']);
    });

    test('handles mixed resolved and unresolved', () {
      final resolved = resolveVars(
        'Hi {{contact_name}}, re: {{record_title}}',
        {'contact_name': 'Jane'},
      );
      final unresolved = findUnresolved(resolved);
      expect(unresolved, ['{{record_title}}']);
    });

    test('handles empty string', () {
      expect(findUnresolved(''), isEmpty);
    });

    test('does not match single braces', () {
      expect(findUnresolved('Hi {name}!'), isEmpty);
    });

    test('does not match triple braces', () {
      expect(findUnresolved('Hi {{{name}}}!'), isNotEmpty);
    });
  });

  group('buildTemplateVars', () {
    test('builds contact vars from recipient', () {
      final vars = buildTemplateVars(
        recipientEmail: 'jane@acme.com',
        recipientName: 'Jane Doe',
      );
      expect(vars['contact_email'], 'jane@acme.com');
      expect(vars['contact_name'], 'Jane Doe');
      expect(vars['contact_first_name'], 'Jane');
    });

    test('builds user vars', () {
      final vars = buildTemplateVars(
        userName: 'John Smith',
        userEmail: 'john@crm.com',
      );
      expect(vars['user_name'], 'John Smith');
      expect(vars['user_email'], 'john@crm.com');
    });

    test('builds company and record vars', () {
      final vars = buildTemplateVars(
        companyName: 'Acme Corp',
        recordTitle: 'Fix login timeout',
      );
      expect(vars['company_name'], 'Acme Corp');
      expect(vars['record_title'], 'Fix login timeout');
    });

    test('builds date var', () {
      final vars = buildTemplateVars(date: 'May 21, 2026');
      expect(vars['date'], 'May 21, 2026');
    });

    test('returns empty map when no context', () {
      final vars = buildTemplateVars();
      expect(vars, isEmpty);
    });

    test('splits first name from full name', () {
      final vars = buildTemplateVars(recipientName: 'Jane Marie Doe');
      expect(vars['contact_first_name'], 'Jane');
      expect(vars['contact_name'], 'Jane Marie Doe');
    });

    test('handles single-word name', () {
      final vars = buildTemplateVars(recipientName: 'Madonna');
      expect(vars['contact_first_name'], 'Madonna');
      expect(vars['contact_name'], 'Madonna');
    });

    test('full integration: resolve template with all vars', () {
      final vars = buildTemplateVars(
        recipientEmail: 'jane@acme.com',
        recipientName: 'Jane Doe',
        companyName: 'Acme Corp',
        userName: 'John Smith',
        userEmail: 'john@crm.com',
        recordTitle: 'Fix login timeout',
        date: 'May 21, 2026',
      );
      final template =
          'Hi {{contact_first_name}},\n\n'
          'This is {{user_name}} from our team.\n'
          'Re: {{record_title}} at {{company_name}}.\n\n'
          'Please reach me at {{user_email}}.\n'
          'Date: {{date}}';
      final result = resolveVars(template, vars);

      expect(result, contains('Hi Jane,'));
      expect(result, contains('John Smith'));
      expect(result, contains('Fix login timeout'));
      expect(result, contains('Acme Corp'));
      expect(result, contains('john@crm.com'));
      expect(result, contains('May 21, 2026'));
      expect(findUnresolved(result), isEmpty);
    });
  });
}
