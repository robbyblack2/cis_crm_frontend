import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:flutter/material.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({required this.result, super.key});

  final SearchResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(result.title),
      subtitle: result.subtitle != null ? Text(result.subtitle!) : null,
      trailing: result.matchedField != null
          ? Chip(label: Text(result.matchedField!))
          : null,
    );
  }
}
