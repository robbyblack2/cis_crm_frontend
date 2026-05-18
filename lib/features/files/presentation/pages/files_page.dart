import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_cubit.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
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
      appBar: AppBar(title: const Text('Files')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Upload file',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          );
        },
        child: const Icon(Icons.upload_file),
      ),
      body: BlocBuilder<FilesCubit, FilesState>(
        builder: (context, state) {
          return switch (state) {
            FilesInitial() => const EmptyState(
                icon: Icons.folder_open,
                title: 'No parent context',
                message:
                    'Select a contact or record to view its files.',
              ),
            FilesLoading() ||
            FilesUploading() =>
              const PageLoading(),
            FilesLoaded(:final files) when files.isEmpty => const EmptyState(
                icon: Icons.folder_open,
                title: 'No files',
                message: 'Upload your first file to get started.',
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
                title: 'Failed to load files',
                message: failure.message,
                onRetry: () {
                  // No parent context available from standalone files page.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Select a contact or record to view its files.',
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
}
