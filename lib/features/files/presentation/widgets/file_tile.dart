import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  const FileTile({required this.file, this.onTap, this.onDelete, super.key});

  final FileAttachment file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          _iconForContentType(file.contentType),
          size: 36,
          color: _colorForContentType(file.contentType, context),
        ),
        title: Text(
          file.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${_formatSize(file.sizeBytes)} · ${file.contentType}'),
        trailing: onDelete != null
            ? IconButton(
                tooltip: 'Delete file',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  static IconData _iconForContentType(String contentType) {
    if (contentType.startsWith('image/')) return Icons.image_outlined;
    if (contentType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (contentType.startsWith('text/')) return Icons.article_outlined;
    if (contentType.contains('spreadsheet') || contentType.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (contentType.contains('presentation') ||
        contentType.contains('powerpoint')) {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static Color _colorForContentType(
    String contentType,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (contentType.startsWith('image/')) return colorScheme.tertiary;
    if (contentType == 'application/pdf') return colorScheme.error;
    return colorScheme.primary;
  }
}
