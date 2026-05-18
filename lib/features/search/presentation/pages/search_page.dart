import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/presentation/bloc/search_bloc.dart';
import 'package:cis_crm/features/search/presentation/widgets/search_result_group.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchFieldHint,
            border: InputBorder.none,
            suffixIcon: IconButton(
              tooltip: AppLocalizations.of(context)!.clearSearch,
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                context.read<SearchBloc>().add(const SearchCleared());
              },
            ),
          ),
          onChanged: (query) {
            context.read<SearchBloc>().add(SearchQueryChanged(query: query));
          },
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          return switch (state) {
            SearchInitial() => EmptyState(
                icon: Icons.search,
                title: AppLocalizations.of(context)!.searchCrmTitle,
                message: AppLocalizations.of(context)!.searchCrmMessage,
              ),
            SearchLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            SearchLoaded(:final results) => _GroupedResultsList(
                results: results,
              ),
            SearchEmpty(:final query) => EmptyState(
                icon: Icons.search_off,
                title: AppLocalizations.of(context)!.searchNoResultsTitle,
                message: AppLocalizations.of(context)!.searchNoMatchesFor(query),
              ),
            SearchError(:final failure) => PageError(
                title: AppLocalizations.of(context)!.searchFailed,
                message: failure.message,
                onRetry: () {
                  final query = _controller.text;
                  if (query.isNotEmpty) {
                    context
                        .read<SearchBloc>()
                        .add(SearchQueryChanged(query: query));
                  }
                },
              ),
          };
        },
      ),
    );
  }
}

class _GroupedResultsList extends StatelessWidget {
  const _GroupedResultsList({required this.results});

  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SearchResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.entityType, () => []).add(result);
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
