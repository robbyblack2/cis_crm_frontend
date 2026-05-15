import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/presentation/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';

class SearchResultGroup extends StatelessWidget {
  const SearchResultGroup({
    required this.entityType,
    required this.results,
    super.key,
  });

  final String entityType;
  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            entityType,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...results.map((r) => SearchResultTile(result: r)),
      ],
    );
  }
}
