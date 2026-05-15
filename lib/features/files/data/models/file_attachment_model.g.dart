// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_attachment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileAttachmentModel _$FileAttachmentModelFromJson(Map<String, dynamic> json) =>
    FileAttachmentModel(
      id: json['id'] as String,
      filename: json['filename'] as String,
      contentType: json['content_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      s3Key: json['s3_key'] as String,
      contentHash: json['content_hash'] as String,
      parentType: json['parent_type'] as String,
      parentId: json['parent_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FileAttachmentModelToJson(
        FileAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filename': instance.filename,
      'content_type': instance.contentType,
      'size_bytes': instance.sizeBytes,
      's3_key': instance.s3Key,
      'content_hash': instance.contentHash,
      'parent_type': instance.parentType,
      'parent_id': instance.parentId,
      'uploaded_by': instance.uploadedBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
