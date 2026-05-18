import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class FilePreviewWidget extends StatelessWidget {
  const FilePreviewWidget({required this.file, super.key});

  final FileAttachment file;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.preview_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              file.filename,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatSize(file.sizeBytes)} · ${file.contentType}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.uploadedBy(file.uploadedBy),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                // TODO(files): Implement file download/preview.
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(AppLocalizations.of(context)!.openPreview),
            ),
          ],
        ),
      ),
    );
  }
}
