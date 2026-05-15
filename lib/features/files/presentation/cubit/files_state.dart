import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class FilesState extends Equatable {
  const FilesState();

  @override
  List<Object?> get props => [];
}

final class FilesInitial extends FilesState {
  const FilesInitial();
}

final class FilesLoading extends FilesState {
  const FilesLoading();
}

final class FilesLoaded extends FilesState {
  const FilesLoaded(this.files);

  final List<FileAttachment> files;

  @override
  List<Object?> get props => [files];
}

final class FilesUploading extends FilesState {
  const FilesUploading(this.files);

  final List<FileAttachment> files;

  @override
  List<Object?> get props => [files];
}

final class FilesError extends FilesState {
  const FilesError(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
