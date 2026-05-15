import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/presentation/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';

class SearchResultGroup extends StatelessWidget {
  const SearchResultGroup({
    required this.entityType,
    required this.results,
    this.onResultTap,
    super.key,
  });

  final String entityType;
  final List<SearchResult> results;
  final void Function(SearchResult result)? onResultTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _displayName(entityType),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...results.map(
          (result) => SearchResultTile(
            result: result,
            onTap: onResultTap != null ? () => onResultTap!(result) : null,
          ),
        ),
        const Divider(),
      ],
    );
  }

  static String _displayName(String entityType) {
    return switch (entityType) {
      'contacts' => 'Contacts',
      'pipeline' => 'Pipeline',
      'calendar' => 'Calendar',
      'email' => 'Email',
      'files' => 'Files',
      'automation' => 'Automation',
      'products' => 'Products',
      _ => entityType[0].toUpperCase() + entityType.substring(1),
    };
  }
}
