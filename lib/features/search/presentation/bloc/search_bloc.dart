import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/domain/repositories/search_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<SearchCleared>(_onCleared, transformer: droppable());
  }

  final SearchRepository _repository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      if (state is! SearchInitial) {
        emit(const SearchInitial());
      }
      return;
    }

    emit(const SearchLoading());

    final result = await _repository.search(query: query, type: event.type);

    switch (result) {
      case Success(data: final results):
        if (results.isEmpty) {
          emit(SearchEmpty(query: query));
        } else {
          emit(SearchLoaded(results: results, query: query));
        }
      case Failure(error: final failure):
        emit(SearchError(failure: failure));
    }
  }

  void _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchInitial());
  }
}
