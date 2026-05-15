import 'package:cis_crm/features/files/presentation/cubit/files_cubit.dart';
import 'package:cis_crm/features/files/presentation/cubit/files_state.dart';
import 'package:cis_crm/features/files/presentation/widgets/file_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({
    required this.parentType,
    required this.parentId,
    super.key,
  });

  final String parentType;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: BlocBuilder<FilesCubit, FilesState>(
        builder: (context, state) {
          return switch (state) {
            FilesInitial() => const Center(child: Text('No files loaded.')),
            FilesLoading() => const Center(child: CircularProgressIndicator()),
            FilesUploading(:final files) => Column(
                children: [
                  const LinearProgressIndicator(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) =>
                          FileTile(file: files[index]),
                    ),
                  ),
                ],
              ),
            FilesLoaded(:final files) => files.isEmpty
                ? const Center(child: Text('No files.'))
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) =>
                        FileTile(file: files[index]),
                  ),
            FilesError(:final failure) => Center(child: Text(failure.message)),
          };
        },
      ),
    );
  }
}
