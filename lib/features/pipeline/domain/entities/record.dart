import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum RecordSource { manual, email, syncRule, automation }

@immutable
class PipelineRecord extends Equatable {
  const PipelineRecord({
    required this.id,
    required this.pipelineId,
    required this.stageId,
    required this.title,
    required this.source,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.contactId,
    this.companyId,
    this.ownerId,
  });

  final String id;
  final String pipelineId;
  final String stageId;
  final String? contactId;
  final String? companyId;
  final String? ownerId;
  final String title;
  final RecordSource source;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        pipelineId,
        stageId,
        contactId,
        companyId,
        ownerId,
        title,
        source,
        tags,
        createdAt,
        updatedAt,
      ];
}
