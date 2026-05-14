import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A generic page result returned by paginated repository calls.
///
/// The same type covers both cursor-based and offset-based APIs — the
/// repo populates whichever fields its server supports. Consumers read
/// [hasMore] to decide whether to fetch another page.
@immutable
class Page<T> extends Equatable {
  const Page({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.nextOffset,
  });

  final List<T> items;
  final bool hasMore;

  /// Populated for cursor-style APIs (`{items, nextCursor, hasMore}`).
  final String? nextCursor;

  /// Populated for offset-style APIs (`{items, total, page, pageSize}`).
  final int? nextOffset;

  static Page<T> empty<T>() => const Page<Never>(items: [], hasMore: false)
      as Page<T>;

  @override
  List<Object?> get props => [items, hasMore, nextCursor, nextOffset];
}
