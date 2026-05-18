import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A paginated response from the API.
///
/// The backend returns:
/// ```json
/// {"data": [...], "meta": {"page": 1, "per_page": 25, "total": 100}}
/// ```
@immutable
class PaginatedResponse<T> extends Equatable {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int total;

  bool get hasMore => page * perPage < total;

  int get nextPage => page + 1;

  static PaginatedResponse<T> empty<T>() => PaginatedResponse<T>(
        items: const [],
        page: 1,
        perPage: 25,
        total: 0,
      );

  @override
  List<Object?> get props => [items, page, perPage, total];
}
