import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'files_state.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit({required FileRepository repository})
      : _repository = repository,
        super(const FilesInitial());

  final FileRepository _repository;

  Future<void> loadFile(String id) async {
    emit(const FilesLoading());
    final result = await _repository.getMetadata(id);
    switch (result) {
      case Success(:final data):
        emit(FilesLoaded([data]));
      case Failure(:final error):
        emit(FilesError(error));
    }
  }

  Future<void> uploadFile({
    required String parentType,
    required String parentId,
    required String filePath,
    required String filename,
  }) async {
    final currentFiles = state is FilesLoaded
        ? (state as FilesLoaded).files
        : <FileAttachment>[];
    emit(FilesUploading(currentFiles));
    final result = await _repository.upload(
      parentType: parentType,
      parentId: parentId,
      filePath: filePath,
      filename: filename,
    );
    switch (result) {
      case Success(:final data):
        emit(FilesLoaded([...currentFiles, data]));
      case Failure(:final error):
        emit(FilesError(error));
    }
  }

  Future<void> deleteFile(String fileId) async {
    final currentState = state;
    if (currentState is! FilesLoaded) return;

    final result = await _repository.delete(fileId);
    switch (result) {
      case Success():
        final updatedFiles =
            currentState.files.where((f) => f.id != fileId).toList();
        emit(FilesLoaded(updatedFiles));
      case Failure(:final error):
        emit(FilesError(error));
    }
  }
}
