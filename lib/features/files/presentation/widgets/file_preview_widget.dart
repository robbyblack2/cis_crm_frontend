import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:flutter/material.dart';

class FilePreviewWidget extends StatelessWidget {
  const FilePreviewWidget({required this.file, super.key});

  final FileAttachment file;

  @override
  Widget build(BuildContext context) {
    final isImage = file.contentType.startsWith('image/');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isImage ? Icons.image : Icons.insert_drive_file,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              file.filename,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB'
              ' - ${file.contentType}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
