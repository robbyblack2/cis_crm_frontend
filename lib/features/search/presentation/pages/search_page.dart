import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/presentation/bloc/search_bloc.dart';
import 'package:cis_crm/features/search/presentation/widgets/search_result_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () =>
                context.read<SearchBloc>().add(const SearchCleared()),
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) => switch (state) {
          SearchInitial() => const Center(
              child: Text('Enter a query to search'),
            ),
          SearchLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          SearchEmpty(:final query) => Center(
              child: Text('No results found for "$query"'),
            ),
          SearchLoaded(:final results) => _buildGroupedResults(results),
          SearchError(:final failure) => Center(
              child: Text(failure.message),
            ),
        },
      ),
    );
  }

  Widget _buildGroupedResults(
    List<SearchResult> results,
  ) {
    final grouped = <String, List<SearchResult>>{};
    for (final result in results) {
      (grouped[result.entityType] ??= []).add(result);
    }

    return ListView(
      children: grouped.entries
          .map(
            (entry) => SearchResultGroup(
              entityType: entry.key,
              results: entry.value,
            ),
          )
          .toList(),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
      ),
      onChanged: (query) =>
          context.read<SearchBloc>().add(SearchQueryChanged(query: query)),
    );
  }
}
