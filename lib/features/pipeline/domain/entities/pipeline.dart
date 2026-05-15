import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum PipelineType { sales, support }

@immutable
class Pipeline extends Equatable {
  const Pipeline({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.pipelineType,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int sortOrder;
  final PipelineType pipelineType;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        sortOrder,
        pipelineType,
        isActive,
        createdAt,
      ];
}
