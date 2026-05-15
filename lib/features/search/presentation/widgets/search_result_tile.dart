import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:flutter/material.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({required this.result, this.onTap, super.key});

  final SearchResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForEntityType(result.entityType)),
      title: Text(result.title),
      subtitle: _buildSubtitle(context),
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final parts = <InlineSpan>[];

    if (result.subtitle != null) {
      parts.add(TextSpan(text: result.subtitle));
    }

    if (result.matchedField != null) {
      if (parts.isNotEmpty) {
        parts.add(const TextSpan(text: ' · '));
      }
      parts.add(
        TextSpan(
          text: 'Matched: ${result.matchedField}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;

    return Text.rich(TextSpan(children: parts));
  }

  static IconData _iconForEntityType(String entityType) {
    return switch (entityType) {
      'contacts' => Icons.person_outlined,
      'pipeline' => Icons.dashboard_outlined,
      'calendar' => Icons.calendar_today_outlined,
      'email' => Icons.email_outlined,
      'files' => Icons.folder_outlined,
      'automation' => Icons.bolt_outlined,
      'products' => Icons.inventory_2_outlined,
      _ => Icons.search_outlined,
    };
  }
}
