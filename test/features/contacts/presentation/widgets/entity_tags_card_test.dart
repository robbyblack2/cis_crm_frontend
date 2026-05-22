import 'package:cis_crm/core/widgets/crm_tag_chip.dart';
import 'package:cis_crm/features/contacts/presentation/widgets/entity_tags_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityTagsCard', () {
    testWidgets('renders existing tags as CrmTagChip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTagsCard(
              tags: const ['vip', 'partner'],
              availableTags: const ['vip', 'partner', 'lead'],
              onTagsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CrmTagChip), findsNWidgets(2));
      expect(find.text('vip'), findsOneWidget);
      expect(find.text('partner'), findsOneWidget);
    });

    testWidgets('shows Add button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTagsCard(
              tags: const [],
              availableTags: const ['vip'],
              onTagsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('calls onTagsChanged when tag is removed', (tester) async {
      List<String>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTagsCard(
              tags: const ['vip', 'partner'],
              availableTags: const ['vip', 'partner'],
              onTagsChanged: (tags) => result = tags,
            ),
          ),
        ),
      );

      // Find the delete icon on the first CrmTagChip
      final deleteIcons = find.byIcon(Icons.close);
      expect(deleteIcons, findsNWidgets(2));

      await tester.tap(deleteIcons.first);
      await tester.pump();

      expect(result, isNotNull);
      expect(result, hasLength(1));
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityTagsCard(
              tags: const [],
              availableTags: const [],
              onTagsChanged: (_) {},
              title: 'Company Tags',
            ),
          ),
        ),
      );

      expect(find.text('Company Tags'), findsOneWidget);
    });
  });
}
