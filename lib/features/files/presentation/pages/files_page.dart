import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_cubit.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FilesCubit>(),
      child: const _FilesView(),
    );
  }
}

class _FilesView extends StatelessWidget {
  const _FilesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.filesTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: AppLocalizations.of(context)!.uploadFile,
        onPressed: () => _pickAndUploadFile(context),
        child: const Icon(Icons.upload_file),
      ),
      body: BlocBuilder<FilesCubit, FilesState>(
        builder: (context, state) {
          return switch (state) {
            FilesInitial() => EmptyState(
                icon: Icons.folder_open,
                title: AppLocalizations.of(context)!.filesNoParentContext,
                message: AppLocalizations.of(context)!.filesSelectParent,
              ),
            FilesLoading() ||
            FilesUploading() =>
              const PageLoading(),
            FilesLoaded(:final files) when files.isEmpty => EmptyState(
                icon: Icons.folder_open,
                title: AppLocalizations.of(context)!.filesEmptyTitle,
                message: AppLocalizations.of(context)!.filesEmptyMessage,
              ),
            FilesLoaded(:final files) => ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return FileTile(
                    file: file,
                    onDelete: () {
                      context.read<FilesCubit>().deleteFile(file.id);
                    },
                  );
                },
              ),
            FilesError(:final failure) => PageError(
                title: AppLocalizations.of(context)!.failedToLoadFiles,
                message: failure.message,
                onRetry: () {
                  // No parent context available from standalone files page.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.filesSelectParent,
                      ),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    if (!context.mounted) return;
    await context.read<FilesCubit>().uploadFile(
          parentType: 'general',
          parentId: 'default',
          filePath: file.path!,
          filename: file.name,
        );
  }
}
