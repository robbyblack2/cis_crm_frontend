part of 'search_bloc.dart';

@immutable
sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded({required this.results, required this.query});

  final List<SearchResult> results;
  final String query;

  @override
  List<Object?> get props => [results, query];
}

final class SearchEmpty extends SearchState {
  const SearchEmpty({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchError extends SearchState {
  const SearchError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
