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
    this.senderEmail,
    this.version = 1,
  });

  final String id;
  final String pipelineId;
  final String stageId;
  final String? contactId;
  final String? companyId;
  final String? ownerId;
  final String? senderEmail;
  final String title;
  final RecordSource source;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  PipelineRecord copyWith({
    String? id,
    String? pipelineId,
    String? stageId,
    String? title,
    RecordSource? source,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactId,
    String? companyId,
    String? ownerId,
    String? senderEmail,
    int? version,
  }) {
    return PipelineRecord(
      id: id ?? this.id,
      pipelineId: pipelineId ?? this.pipelineId,
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactId: contactId ?? this.contactId,
      companyId: companyId ?? this.companyId,
      ownerId: ownerId ?? this.ownerId,
      senderEmail: senderEmail ?? this.senderEmail,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pipelineId,
        stageId,
        contactId,
        companyId,
        ownerId,
        senderEmail,
        title,
        source,
        tags,
        createdAt,
        updatedAt,
        version,
      ];
}
