import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class SearchResult extends Equatable {
  const SearchResult({
    required this.id,
    required this.entityType,
    required this.title,
    this.subtitle,
    this.matchedField,
  });

  final String id;
  final String entityType;
  final String title;
  final String? subtitle;
  final String? matchedField;

  @override
  List<Object?> get props => [id, entityType, title, subtitle, matchedField];
}
