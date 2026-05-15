import 'package:cis_crm/features/files/domain/entities/file_attachment.dart';
import 'package:flutter/material.dart';

class FileTile extends StatelessWidget {
  const FileTile({required this.file, super.key});

  final FileAttachment file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(file.filename),
      subtitle: Text('${(file.sizeBytes / 1024).toStringAsFixed(1)} KB'),
      trailing: Text(file.contentType),
    );
  }
}
