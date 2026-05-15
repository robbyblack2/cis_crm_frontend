part of 'files_cubit.dart';

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

final class FilesUploading extends FilesState {
  const FilesUploading(this.currentFiles);

  final List<FileAttachment> currentFiles;

  @override
  List<Object?> get props => [currentFiles];
}

final class FilesLoaded extends FilesState {
  const FilesLoaded(this.files);

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
