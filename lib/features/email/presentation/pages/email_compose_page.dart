import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:cis_crm/features/email/presentation/bloc/email_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailComposePage extends StatelessWidget {
  const EmailComposePage({
    super.key,
    this.initialTo,
    this.initialToName,
    this.initialCompanyName,
    this.contactId,
    this.recordId,
    this.recordTitle,
    this.draftId,
  });

  final String? initialTo;
  final String? initialToName;
  final String? initialCompanyName;
  final String? contactId;
  final String? recordId;
  final String? recordTitle;
  final String? draftId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmailBloc>(),
      child: _EmailComposeView(
        initialTo: initialTo,
        initialToName: initialToName,
        initialCompanyName: initialCompanyName,
        contactId: contactId,
        recordId: recordId,
        recordTitle: recordTitle,
        draftId: draftId,
      ),
    );
  }
}

class _EmailComposeView extends StatefulWidget {
  const _EmailComposeView({
    this.initialTo,
    this.initialToName,
    this.initialCompanyName,
    this.contactId,
    this.recordId,
    this.recordTitle,
    this.draftId,
  });

  final String? initialTo;
  final String? initialToName;
  final String? initialCompanyName;
  final String? contactId;
  final String? recordId;
  final String? recordTitle;
  final String? draftId;

  @override
  State<_EmailComposeView> createState() => _EmailComposeViewState();
}

class _AttachedFile {
  const _AttachedFile({required this.name, required this.bytes});
  final String name;
  final List<int> bytes;
}

class _EmailComposeViewState extends State<_EmailComposeView> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bodyFocusNode = FocusNode();
  final _toRecipients = <_Recipient>[];
  final _ccRecipients = <_Recipient>[];
  final _attachments = <_AttachedFile>[];
  bool _showCc = false;
  bool _showTemplatePanel = false;
  String _templateSearch = '';
  List<EmailTemplate> _templates = [];
  String? _recordTitle;

  static final _placeholderRe = RegExp(r'\{\{[^}]+\}\}');

  int get _unresolvedCount =>
      _placeholderRe.allMatches(_subjectCtrl.text).length +
      _placeholderRe.allMatches(_bodyCtrl.text).length;

  List<String> get _unresolvedList {
    final all = <String>{};
    for (final m in _placeholderRe.allMatches(_subjectCtrl.text)) {
      all.add(m.group(0)!);
    }
    for (final m in _placeholderRe.allMatches(_bodyCtrl.text)) {
      all.add(m.group(0)!);
    }
    return all.toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
      _toRecipients.add(_Recipient(
        email: widget.initialTo!,
        name: widget.initialToName,
        companyName: widget.initialCompanyName,
      ));
    }
    _recordTitle = widget.recordTitle;
    _loadTemplates();
    if (widget.draftId != null) {
      _loadDraft(widget.draftId!);
    } else {
      _loadSignature();
    }
    _subjectCtrl.addListener(_onTextChanged);
    _bodyCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDraft(String draftId) async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/email/drafts/$draftId',
      );
      final draft = response.data?['data'] as Map<String, dynamic>?;
      if (draft != null && mounted) {
        final recipients = (draft['to_addresses'] as List<dynamic>?) ??
            (draft['to'] as List<dynamic>?) ??
            [];
        setState(() {
          _toRecipients.clear();
          for (final r in recipients) {
            _toRecipients.add(_Recipient(email: r as String));
          }
          _subjectCtrl.text = draft['subject'] as String? ?? '';
          _bodyCtrl.text = draft['body_html'] as String? ??
              draft['body'] as String? ??
              '';
        });
      }
    } catch (_) {
      // Draft load failed — user can compose from scratch.
    }
  }

  Future<void> _loadSignature() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/settings/email-signature',
      );
      final sig = response.data?['data']?['signature'] as String?;
      if (sig != null && sig.isNotEmpty && _bodyCtrl.text.isEmpty) {
        _bodyCtrl.text = '\n\n--\n$sig';
        _bodyCtrl.selection = const TextSelection.collapsed(offset: 0);
      }
    } catch (_) {}
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await getIt<EmailRemoteDataSource>().getTemplates();
      if (mounted) setState(() => _templates = templates);
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _wrapSelection(String openTag, String closeTag) {
    final text = _bodyCtrl.text;
    final sel = _bodyCtrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final before = text.substring(0, sel.start);
    final selected = text.substring(sel.start, sel.end);
    final after = text.substring(sel.end);

    _bodyCtrl.text = '$before$openTag$selected$closeTag$after';
    _bodyCtrl.selection = TextSelection.collapsed(
      offset: sel.start + openTag.length + selected.length + closeTag.length,
    );
    _bodyFocusNode.requestFocus();
  }

  void _insertLink() {
    final urlCtrl = TextEditingController();
    final text = _bodyCtrl.text;
    final sel = _bodyCtrl.selection;
    final linkText = sel.isValid && !sel.isCollapsed
        ? text.substring(sel.start, sel.end)
        : '';

    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Link'),
        content: TextField(
          controller: urlCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, urlCtrl.text),
            child: const Text('Insert'),
          ),
        ],
      ),
    ).then((url) {
      if (url == null || url.trim().isEmpty) return;
      final display = linkText.isNotEmpty ? linkText : url;
      final html = '<a href="$url">$display</a>';

      if (sel.isValid && !sel.isCollapsed) {
        final before = text.substring(0, sel.start);
        final after = text.substring(sel.end);
        _bodyCtrl.text = '$before$html$after';
      } else {
        final pos = sel.isValid ? sel.baseOffset : _bodyCtrl.text.length;
        final before = _bodyCtrl.text.substring(0, pos);
        final after = _bodyCtrl.text.substring(pos);
        _bodyCtrl.text = '$before$html$after';
      }
      _bodyFocusNode.requestFocus();
    });
  }

  Future<void> _attachFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: true,
      );
      if (result == null) return;
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null) {
            _attachments.add(_AttachedFile(
              name: file.name,
              bytes: file.bytes!,
            ));
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach file: $e')),
        );
      }
    }
  }

  void _applyTemplate(EmailTemplate template) {
    var subject = template.subjectTemplate;
    var body = template.bodyTemplate;

    // Resolve variables from context.
    final vars = _buildTemplateVars();
    for (final entry in vars.entries) {
      subject = subject.replaceAll('{{${entry.key}}}', entry.value);
      body = body.replaceAll('{{${entry.key}}}', entry.value);
    }

    final hasContent = _subjectCtrl.text.trim().isNotEmpty ||
        _bodyCtrl.text.trim().isNotEmpty;

    if (hasContent) {
      // Confirm before replacing existing content.
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Apply Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will replace your current content.'),
              const SizedBox(height: 16),
              Text('Subject:', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subject.isNotEmpty ? subject : '(empty)', style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              Text('Body preview:', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    body.isNotEmpty ? body : '(empty)',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) {
          setState(() {
            _subjectCtrl.text = subject;
            _bodyCtrl.text = body;
          });
        }
      });
    } else {
      setState(() {
        _subjectCtrl.text = subject;
        _bodyCtrl.text = body;
      });
    }
  }

  /// Re-resolve template variables when a recipient is added.
  void _reResolveTemplateVars() {
    final vars = _buildTemplateVars();
    if (vars.isEmpty) return;
    var subject = _subjectCtrl.text;
    var body = _bodyCtrl.text;
    for (final entry in vars.entries) {
      subject = subject.replaceAll('{{${entry.key}}}', entry.value);
      body = body.replaceAll('{{${entry.key}}}', entry.value);
    }
    setState(() {
      _subjectCtrl.text = subject;
      _bodyCtrl.text = body;
    });
  }

  Map<String, String> _buildTemplateVars() {
    final vars = <String, String>{};

    // From the first To recipient (contact context).
    if (_toRecipients.isNotEmpty) {
      final r = _toRecipients.first;
      if (r.email.isNotEmpty) vars['contact_email'] = r.email;
      if (r.name != null && r.name!.isNotEmpty) {
        vars['contact_name'] = r.name!;
        final parts = r.name!.split(' ');
        if (parts.isNotEmpty) vars['contact_first_name'] = parts.first;
      }
      if (r.companyName != null && r.companyName!.isNotEmpty) {
        vars['company_name'] = r.companyName!;
      }
    }

    // Current user context from AuthBloc.
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        if (user.displayName.isNotEmpty) vars['user_name'] = user.displayName;
        if (user.email.isNotEmpty) vars['user_email'] = user.email;
      }
    } catch (_) {
      // AuthBloc may not be in the widget tree in some contexts.
    }

    // Record title from widget context.
    if (_recordTitle != null && _recordTitle!.isNotEmpty) {
      vars['record_title'] = _recordTitle!;
    }

    // Date.
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    vars['date'] = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return vars;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocListener<EmailBloc, EmailState>(
      listener: (context, state) {
        switch (state) {
          case EmailLoaded(sentMessage: final msg) when msg != null:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.emailSentSuccess)),
            );
            Navigator.of(context).pop();
          case EmailLoaded(savedDraft: final draft) when draft != null:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.draftSaved)),
            );
          case EmailError(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          case _:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(l10n.emailComposeTitle),
          actions: [
            BlocBuilder<EmailBloc, EmailState>(
              builder: (context, state) {
                final isSending = state is EmailLoading;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Draft'),
                      onPressed: isSending ? null : _saveDraft,
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      onPressed: isSending ? null : _sendEmail,
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              },
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
            const SizedBox(height: 4),

            // ── To Field ──
            _RecipientChipField(
              label: l10n.emailTo,
              recipients: _toRecipients,
              onChanged: () {
                setState(() {});
                _reResolveTemplateVars();
              },
            ),

            // ── CC Toggle / Field ──
            if (!_showCc)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _showCc = true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text('CC', style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                  )),
                ),
              )
            else
              _RecipientChipField(
                label: 'CC',
                recipients: _ccRecipients,
                onChanged: () => setState(() {}),
              ),

            const Divider(height: 1),
            const SizedBox(height: 4),

            // ── Subject ──
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                hintText: 'Subject',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 8,
                ),
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              style: theme.textTheme.titleMedium,
            ),

            const Divider(height: 1),

            // ── Body (borderless, Gmail-style) ──
            TextField(
              controller: _bodyCtrl,
              focusNode: _bodyFocusNode,
              decoration: const InputDecoration(
                hintText: 'Compose email...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              maxLines: null,
              minLines: 10,
              style: theme.textTheme.bodyMedium,
            ),

            // ── Attachments List ──
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _attachments.asMap().entries.map((entry) {
                  return Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      entry.value.name,
                      style: theme.textTheme.labelSmall,
                    ),
                    onDeleted: () => setState(() =>
                        _attachments.removeAt(entry.key)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // ── Unresolved placeholder warning ──
            if (_unresolvedCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_unresolvedCount unresolved: ${_unresolvedList.join(', ')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Bottom Toolbar (Gmail/HubSpot-style) ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  _FormatButton(
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onTap: () => _wrapSelection('<b>', '</b>'),
                  ),
                  _FormatButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    onTap: () => _wrapSelection('<i>', '</i>'),
                  ),
                  _FormatButton(
                    icon: Icons.format_underlined,
                    tooltip: 'Underline',
                    onTap: () => _wrapSelection('<u>', '</u>'),
                  ),
                  _FormatButton(
                    icon: Icons.link,
                    tooltip: 'Insert link',
                    onTap: _insertLink,
                  ),
                  _FormatButton(
                    icon: Icons.attach_file,
                    tooltip: 'Attach file',
                    onTap: _attachFile,
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: cs.outlineVariant,
                  ),
                  // Templates button
                  Tooltip(
                    message: 'Use template',
                    child: InkWell(
                      onTap: () => setState(() {
                        _showTemplatePanel = !_showTemplatePanel;
                        _templateSearch = '';
                      }),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _showTemplatePanel
                              ? cs.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: _showTemplatePanel
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Templates',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _showTemplatePanel
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontWeight: _showTemplatePanel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Template Selection Panel ──
            if (_showTemplatePanel && _templates.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search templates...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,
                          ),
                        ),
                        style: theme.textTheme.bodySmall,
                        onChanged: (v) => setState(() => _templateSearch = v),
                      ),
                    ),
                    const Divider(height: 1),
                    // Template list
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: _templates
                            .where((t) => _templateSearch.isEmpty ||
                                t.name.toLowerCase().contains(
                                    _templateSearch.toLowerCase()))
                            .map((t) => _TemplateListItem(
                                  template: t,
                                  onSelect: () {
                                    _applyTemplate(t);
                                    setState(() => _showTemplatePanel = false);
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showTemplatePanel && _templates.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  'No templates yet. Create templates in Settings > Email Templates.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmail() async {
    if (_toRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one recipient')),
      );
      return;
    }
    if (_subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.emailSubjectRequired)),
      );
      return;
    }

    // Check for unresolved template placeholders.
    final placeholderPattern = RegExp(r'\{\{[^}]+\}\}');
    final subjectPlaceholders =
        placeholderPattern.allMatches(_subjectCtrl.text).map((m) => m.group(0)!).toList();
    final bodyPlaceholders =
        placeholderPattern.allMatches(_bodyCtrl.text).map((m) => m.group(0)!).toList();
    final allPlaceholders = [...subjectPlaceholders, ...bodyPlaceholders];

    if (allPlaceholders.isNotEmpty) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unresolved Placeholders'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your email contains unresolved template variables:',
              ),
              const SizedBox(height: 12),
              ...allPlaceholders.toSet().map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '  $p',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              const Text(
                'Add a contact to the To field or manually replace '
                'the {{}} placeholders before sending.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go Back and Fix'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send Anyway'),
            ),
          ],
        ),
      ).then((sendAnyway) {
        if (sendAnyway == true) _doSend();
      });
      return;
    }

    _doSend();
  }

  void _doSend() {
    final cc = _ccRecipients.map((r) => r.email).toList();
    context.read<EmailBloc>().add(
          EmailSendRequested(
            recipientEmails: _toRecipients.map((r) => r.email).toList(),
            subject: _subjectCtrl.text,
            body: _bodyCtrl.text,
            contactId: widget.contactId,
            recordId: widget.recordId,
            cc: cc.isNotEmpty ? cc : null,
          ),
        );
  }

  void _saveDraft() {
    context.read<EmailBloc>().add(
          DraftSaveRequested(
            recipientEmails: _toRecipients.map((r) => r.email).toList(),
            subject: _subjectCtrl.text,
            body: _bodyCtrl.text,
          ),
        );
  }
}

// ── Recipient data ──

class _Recipient {
  const _Recipient({required this.email, this.name, this.companyName});

  final String email;
  final String? name;
  final String? companyName;

  String get display => name != null ? '$name <$email>' : email;
}

// ── Recipient chip field with contact autocomplete ──

class _RecipientChipField extends StatefulWidget {
  const _RecipientChipField({
    required this.label,
    required this.recipients,
    required this.onChanged,
  });

  final String label;
  final List<_Recipient> recipients;
  final VoidCallback onChanged;

  @override
  State<_RecipientChipField> createState() => _RecipientChipFieldState();
}

class _RecipientChipFieldState extends State<_RecipientChipField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final response = await getIt<ContactRemoteDataSource>()
            .getContacts(page: 1, perPage: 10);
        final q = query.toLowerCase();
        final results = response.items
            .where((c) {
              final name = '${c.firstName} ${c.lastName}'.toLowerCase();
              return name.contains(q) || c.email.toLowerCase().contains(q);
            })
            .map((c) => {
                  'name': '${c.firstName} ${c.lastName}'.trim(),
                  'email': c.email,
                })
            .toList();
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {}
    });
  }

  void _addRecipient(_Recipient r) {
    widget.recipients.add(r);
    _ctrl.clear();
    setState(() => _suggestions = []);
    widget.onChanged();
    _focusNode.requestFocus();
  }

  void _removeRecipient(int index) {
    widget.recipients.removeAt(index);
    widget.onChanged();
  }

  void _submitRaw() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _addRecipient(_Recipient(email: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...widget.recipients.asMap().entries.map((entry) {
                final r = entry.value;
                return Chip(
                  label: Text(
                    r.display,
                    style: theme.textTheme.labelSmall,
                  ),
                  onDeleted: () => _removeRecipient(entry.key),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type name or email...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: theme.textTheme.bodySmall,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submitRaw(),
                ),
              ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                ..._suggestions.map((s) {
                  final name = s['name'] as String? ?? '';
                  final email = s['email'] as String? ?? '';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, size: 18),
                    title: Text(name, style: theme.textTheme.bodySmall),
                    subtitle: Text(email,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    onTap: () =>
                        _addRecipient(_Recipient(email: email, name: name)),
                  );
                }),
                if (_ctrl.text.contains('@'))
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.email_outlined,
                        size: 18, color: cs.primary),
                    title: Text(
                      'Use "${_ctrl.text}" as email',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.primary),
                    ),
                    onTap: _submitRaw,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Formatting toolbar button ──

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// Template list item with subject/body preview on hover/expand.
class _TemplateListItem extends StatefulWidget {
  const _TemplateListItem({
    required this.template,
    required this.onSelect,
  });

  final EmailTemplate template;
  final VoidCallback onSelect;

  @override
  State<_TemplateListItem> createState() => _TemplateListItemState();
}

class _TemplateListItemState extends State<_TemplateListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = widget.template;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          leading: Icon(Icons.description_outlined, size: 18,
              color: cs.onSurfaceVariant),
          title: Text(
            t.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: t.subjectTemplate.isNotEmpty
              ? Text(
                  t.subjectTemplate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                tooltip: _expanded ? 'Hide preview' : 'Preview',
                onPressed: () => setState(() => _expanded = !_expanded),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(width: 4),
              FilledButton.tonal(
                onPressed: widget.onSelect,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Use'),
              ),
            ],
          ),
        ),
        // Preview panel
        if (_expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.subjectTemplate.isNotEmpty) ...[
                  Text(
                    'Subject: ${t.subjectTemplate}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],
                Text(
                  t.bodyTemplate.isNotEmpty
                      ? t.bodyTemplate
                      : '(no body)',
                  style: theme.textTheme.bodySmall,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                // Show variables used
                if (t.variables != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _extractVarNames(t.bodyTemplate + t.subjectTemplate)
                        .map((v) => Chip(
                              label: Text(v,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                  )),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              backgroundColor: cs.primaryContainer,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  List<String> _extractVarNames(String text) {
    final pattern = RegExp(r'\{\{([^}]+)\}\}');
    return pattern
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }
}
