import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class EmailSignaturePage extends StatefulWidget {
  const EmailSignaturePage({super.key});

  @override
  State<EmailSignaturePage> createState() => _EmailSignaturePageState();
}

class _EmailSignaturePageState extends State<EmailSignaturePage> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/settings/email-signature',
      );
      final data = response.data?['data'];
      if (mounted) {
        setState(() {
          _ctrl.text = data is String ? data : data?.toString() ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<Dio>().put<void>(
        '/api/settings/email-signature',
        data: {'value': _ctrl.text},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Signature'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Email signature (HTML supported)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 15,
                minLines: 5,
              ),
            ),
    );
  }
}
