import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entities = ['contact', 'company', 'record', 'product'];

    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Export section ──
          Text(
            'Export',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...entities.map(
            (entity) => Card(
              child: ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(
                  'Export ${entity[0].toUpperCase()}${entity.substring(1)}s',
                ),
                subtitle: const Text('Download as CSV'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _export(context, entity),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Import section ──
          Text(
            'Import',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...entities.map(
            (entity) => Card(
              child: ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: Text(
                  'Import ${entity[0].toUpperCase()}${entity.substring(1)}s',
                ),
                subtitle: const Text('Upload CSV file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _import(context, entity),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Download templates ──
          Text(
            'Templates',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...entities.map(
            (entity) => Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  '${entity[0].toUpperCase()}${entity.substring(1)} '
                  'template',
                ),
                subtitle: const Text('Download CSV template'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _downloadTemplate(context, entity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, String entityType) async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/export/$entityType',
      );
      if (!context.mounted) return;
      final data = response.data?['data'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data != null
                ? 'Export ready: $data'
                : 'Export complete',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, String entityType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    if (!context.mounted) return;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });
      await getIt<Dio>().post<void>(
        '/api/import/$entityType',
        data: formData,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${entityType[0].toUpperCase()}'
              '${entityType.substring(1)}s imported',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadTemplate(
    BuildContext context,
    String entityType,
  ) async {
    try {
      await getIt<Dio>().get<void>(
        '/api/import/templates/$entityType',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
