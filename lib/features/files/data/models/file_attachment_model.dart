import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'file_attachment_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FileAttachmentModel extends FileAttachment {
  const FileAttachmentModel({
    required super.id,
    required super.filename,
    required super.contentType,
    required super.sizeBytes,
    required super.s3Key,
    required super.contentHash,
    required super.parentType,
    required super.parentId,
    required super.uploadedBy,
    required super.createdAt,
  });

  factory FileAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$FileAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$FileAttachmentModelToJson(this);
}
