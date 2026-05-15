// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallLogModel _$CallLogModelFromJson(Map<String, dynamic> json) => CallLogModel(
      id: json['id'] as String,
      contactId: json['contact_id'] as String,
      direction: $enumDecode(_$CallDirectionEnumMap, json['direction']),
      outcome: $enumDecode(_$CallOutcomeEnumMap, json['outcome']),
      loggedBy: json['logged_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      recordId: json['record_id'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CallLogModelToJson(CallLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contact_id': instance.contactId,
      'record_id': instance.recordId,
      'direction': _$CallDirectionEnumMap[instance.direction]!,
      'outcome': _$CallOutcomeEnumMap[instance.outcome]!,
      'duration_seconds': instance.durationSeconds,
      'notes': instance.notes,
      'logged_by': instance.loggedBy,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$CallDirectionEnumMap = {
  CallDirection.inbound: 'inbound',
  CallDirection.outbound: 'outbound',
};

const _$CallOutcomeEnumMap = {
  CallOutcome.connected: 'connected',
  CallOutcome.voicemail: 'voicemail',
  CallOutcome.noAnswer: 'noAnswer',
  CallOutcome.busy: 'busy',
};
