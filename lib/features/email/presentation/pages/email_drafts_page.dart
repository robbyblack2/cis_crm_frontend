import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EmailDraftsPage extends StatefulWidget {
  const EmailDraftsPage({super.key});

  @override
  State<EmailDraftsPage> createState() => _EmailDraftsPageState();
}

class _EmailDraftsPageState extends State<EmailDraftsPage> {
  List<EmailDraft>? _drafts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final drafts = await getIt<EmailRemoteDataSource>().getDrafts();
      if (mounted) setState(() { _drafts = drafts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _drafts = []; _loading = false; });
    }
  }

  Future<void> _sendDraft(EmailDraft draft) async {
    try {
      await getIt<EmailRemoteDataSource>().sendDraft(id: draft.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft sent')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Drafts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'drafts_fab',
        onPressed: () => context.push(Routes.emailCompose),
        icon: const Icon(Icons.edit),
        label: const Text('New Email'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts == null || _drafts!.isEmpty
              ? const EmptyState(
                  icon: Icons.drafts_outlined,
                  title: 'No drafts',
                  message: 'Saved drafts will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drafts!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final draft = _drafts![index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.drafts_outlined,
                            color: cs.onSurfaceVariant),
                        title: Text(
                          draft.subject.isNotEmpty
                              ? draft.subject
                              : '(no subject)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'To: ${draft.recipientEmails.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.MMMd().format(draft.createdAt),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.send, size: 18,
                                  color: cs.primary),
                              tooltip: 'Send now',
                              onPressed: () => _sendDraft(draft),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push(
                            '${Routes.emailCompose}?draft_id=${draft.id}',
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
