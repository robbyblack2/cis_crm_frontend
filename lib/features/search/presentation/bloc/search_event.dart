part of 'search_bloc.dart';

@immutable
sealed class SearchEvent extends Equatable {
  const SearchEvent();
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged({required this.query, this.type});

  final String query;
  final String? type;

  @override
  List<Object?> get props => [query, type];
}

final class SearchCleared extends SearchEvent {
  const SearchCleared();

  @override
  List<Object?> get props => [];
}
