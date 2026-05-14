import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
  final String? nextCursor;
  final int? nextOffset;

  static Page<T> empty<T>() =>
      const Page<Never>(items: [], hasMore: false) as Page<T>;

  @override
  List<Object?> get props => [items, hasMore, nextCursor, nextOffset];
}
