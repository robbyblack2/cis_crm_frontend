import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/features/files/domain/repositories/file_repository.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit({required FileRepository repository})
      : _repository = repository,
        super(const FilesInitial());

  final FileRepository _repository;

  List<FileAttachment> _currentFiles() => switch (state) {
        FilesLoaded(:final files) => files,
        FilesUploading(:final files) => files,
        _ => const [],
      };

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
    final existing = _currentFiles();
    emit(FilesUploading(List.unmodifiable(existing)));
    final result = await _repository.upload(
      parentType: parentType,
      parentId: parentId,
      filePath: filePath,
      filename: filename,
    );
    switch (result) {
      case Success(:final data):
        emit(FilesLoaded([...existing, data]));
      case Failure(:final error):
        emit(FilesError(error));
    }
  }

  Future<void> deleteFile(String id) async {
    final existing = _currentFiles();
    final result = await _repository.delete(id);
    switch (result) {
      case Success():
        emit(
          FilesLoaded(
            existing.where((f) => f.id != id).toList(),
          ),
        );
      case Failure(:final error):
        emit(FilesError(error));
    }
  }
}
