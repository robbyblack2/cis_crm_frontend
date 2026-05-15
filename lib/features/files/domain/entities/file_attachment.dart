import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class FileAttachment extends Equatable {
  const FileAttachment({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.s3Key,
    required this.contentHash,
    required this.parentType,
    required this.parentId,
    required this.uploadedBy,
    required this.createdAt,
  });

  final String id;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String s3Key;
  final String contentHash;
  final String parentType;
  final String parentId;
  final String uploadedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        filename,
        contentType,
        sizeBytes,
        s3Key,
        contentHash,
        parentType,
        parentId,
        uploadedBy,
        createdAt,
      ];
}
