import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/core/widgets/crm_tag_chip.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactTile extends StatefulWidget {
  const ContactTile({
    required this.contact,
    this.onTap,
    super.key,
  });

  final Contact contact;
  final VoidCallback? onTap;

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  Contact get contact => widget.contact;

  // Editing state — only one field at a time.
  _EditingField? _editing;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  String get _fullName => '${contact.firstName} ${contact.lastName}'.trim();

  String get _initials {
    final first = contact.firstName.isNotEmpty ? contact.firstName[0] : '';
    final last = contact.lastName.isNotEmpty ? contact.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'lead' => Colors.blue,
        'customer' => Colors.green,
        'churned' => Colors.red,
        'prospect' => Colors.orange,
        _ => Colors.grey,
      };

  static const _statusOptions = ['lead', 'prospect', 'customer', 'churned'];

  void _startEditing(_EditingField field) {
    setState(() {
      _editing = field;
      _editCtrl.text = switch (field) {
        _EditingField.name => _fullName,
        _EditingField.email => contact.email,
        _EditingField.phone => contact.phone ?? '',
        _EditingField.jobTitle => contact.jobTitle ?? '',
        _EditingField.status => contact.status,
      };
    });
  }

  void _cancelEditing() {
    setState(() => _editing = null);
  }

  Future<void> _saveField() async {
    final value = _editCtrl.text.trim();
    final field = _editing;
    if (field == null) return;

    Contact updated;
    switch (field) {
      case _EditingField.name:
        final parts = value.split(' ');
        final first = parts.first;
        final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        if (first == contact.firstName && last == contact.lastName) {
          _cancelEditing();
          return;
        }
        updated = contact.copyWith(firstName: first, lastName: last);
      case _EditingField.email:
        if (value == contact.email) { _cancelEditing(); return; }
        updated = contact.copyWith(email: value);
      case _EditingField.phone:
        if (value == (contact.phone ?? '')) { _cancelEditing(); return; }
        updated = contact.copyWith(phone: value);
      case _EditingField.jobTitle:
        if (value == (contact.jobTitle ?? '')) { _cancelEditing(); return; }
        updated = contact.copyWith(jobTitle: value);
      case _EditingField.status:
        if (value == contact.status) { _cancelEditing(); return; }
        updated = contact.copyWith(status: value);
    }

    setState(() => _editing = null);
    await getIt<ContactRepository>().updateContact(updated);
    if (mounted) {
      context.read<ContactsBloc>().add(const ContactsLoadRequested());
    }
  }

  Future<void> _saveStatus(String status) async {
    if (status == contact.status) { _cancelEditing(); return; }
    setState(() => _editing = null);
    final updated = contact.copyWith(status: status);
    await getIt<ContactRepository>().updateContact(updated);
    if (mounted) {
      context.read<ContactsBloc>().add(const ContactsLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(contact.status);

    return InkWell(
      onTap: _editing != null ? null : widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                _initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + job title
            Expanded(
              flex: 3,
              child: _editing == _EditingField.name
                  ? _InlineTextField(
                      controller: _editCtrl,
                      onSave: _saveField,
                      onCancel: _cancelEditing,
                    )
                  : GestureDetector(
                      onDoubleTap: () => _startEditing(_EditingField.name),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _fullName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_editing == _EditingField.jobTitle)
                            _InlineTextField(
                              controller: _editCtrl,
                              onSave: _saveField,
                              onCancel: _cancelEditing,
                              style: theme.textTheme.bodySmall,
                            )
                          else if (contact.jobTitle != null &&
                              contact.jobTitle!.isNotEmpty)
                            GestureDetector(
                              onDoubleTap: () =>
                                  _startEditing(_EditingField.jobTitle),
                              child: Text(
                                contact.jobTitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Email
            Expanded(
              flex: 3,
              child: _editing == _EditingField.email
                  ? _InlineTextField(
                      controller: _editCtrl,
                      onSave: _saveField,
                      onCancel: _cancelEditing,
                      style: theme.textTheme.bodySmall,
                    )
                  : GestureDetector(
                      onDoubleTap: () => _startEditing(_EditingField.email),
                      child: Text(
                        contact.email,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Phone
            Expanded(
              flex: 2,
              child: _editing == _EditingField.phone
                  ? _InlineTextField(
                      controller: _editCtrl,
                      onSave: _saveField,
                      onCancel: _cancelEditing,
                      style: theme.textTheme.bodySmall,
                    )
                  : GestureDetector(
                      onDoubleTap: () => _startEditing(_EditingField.phone),
                      child: Text(
                        contact.phone ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Company (resolved)
            if (contact.companyId != null)
              Expanded(
                flex: 2,
                child: ResolvedName(
                  id: contact.companyId,
                  type: 'company',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
              )
            else
              const Expanded(flex: 2, child: SizedBox.shrink()),
            const SizedBox(width: 8),

            // Status badge (tappable dropdown on double-tap)
            _editing == _EditingField.status
                ? PopupMenuButton<String>(
                    initialValue: contact.status,
                    onSelected: _saveStatus,
                    onCanceled: _cancelEditing,
                    itemBuilder: (_) => _statusOptions
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s[0].toUpperCase() + s.substring(1)),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            contact.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 14, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onDoubleTap: () => _startEditing(_EditingField.status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        contact.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

            // Tags (compact, max 2)
            if (contact.tags.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...contact.tags.take(2).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CrmTagChip(name: tag),
                  )),
              if (contact.tags.length > 2)
                Text(
                  '+${contact.tags.length - 2}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],

            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

enum _EditingField { name, email, phone, jobTitle, status }

/// Compact inline text field for editing within a list row.
class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    required this.onSave,
    required this.onCancel,
    this.style,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextField(
        controller: controller,
        autofocus: true,
        style: style,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        onSubmitted: (_) => onSave(),
        onTapOutside: (_) => onSave(),
      ),
    );
  }
}
