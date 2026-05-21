import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:flutter/material.dart';

/// Dense multi-column company row with double-tap inline editing.
class CompanyTile extends StatefulWidget {
  const CompanyTile({
    required this.company,
    this.onTap,
    this.onUpdated,
    super.key,
  });

  final Company company;
  final VoidCallback? onTap;
  final VoidCallback? onUpdated;

  @override
  State<CompanyTile> createState() => _CompanyTileState();
}

enum _CompanyEditField { name, domain, industry, phone }

class _CompanyTileState extends State<CompanyTile> {
  Company get company => widget.company;

  _CompanyEditField? _editing;
  late final TextEditingController _editCtrl;

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

  void _startEditing(_CompanyEditField field) {
    setState(() {
      _editing = field;
      _editCtrl.text = switch (field) {
        _CompanyEditField.name => company.name,
        _CompanyEditField.domain => company.domain ?? '',
        _CompanyEditField.industry => company.industry ?? '',
        _CompanyEditField.phone => company.phone ?? '',
      };
    });
  }

  void _cancel() => setState(() => _editing = null);

  Future<void> _save() async {
    final value = _editCtrl.text.trim();
    final field = _editing;
    if (field == null) return;

    // Build updated company.
    final updated = Company(
      id: company.id,
      name: field == _CompanyEditField.name ? value : company.name,
      domain: field == _CompanyEditField.domain ? value : company.domain,
      industry: field == _CompanyEditField.industry ? value : company.industry,
      phone: field == _CompanyEditField.phone ? value : company.phone,
      ownerId: company.ownerId,
      employeeCount: company.employeeCount,
      tags: company.tags,
      version: company.version,
      createdAt: company.createdAt,
      updatedAt: company.updatedAt,
    );

    // Skip if unchanged.
    final old = switch (field) {
      _CompanyEditField.name => company.name,
      _CompanyEditField.domain => company.domain ?? '',
      _CompanyEditField.industry => company.industry ?? '',
      _CompanyEditField.phone => company.phone ?? '',
    };
    if (value == old) {
      _cancel();
      return;
    }

    setState(() => _editing = null);
    await getIt<CompanyRepository>().updateCompany(updated);
    widget.onUpdated?.call();
  }

  static const _tagColors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF3B82F6),
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  static Color _colorForTag(String name) {
    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _tagColors[hash.abs() % _tagColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: _editing != null ? null : widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Text(
                company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              flex: 3,
              child: _editing == _CompanyEditField.name
                  ? _InlineField(
                      controller: _editCtrl,
                      onSave: _save,
                      onCancel: _cancel,
                    )
                  : GestureDetector(
                      onDoubleTap: () =>
                          _startEditing(_CompanyEditField.name),
                      child: Text(
                        company.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Domain
            Expanded(
              flex: 2,
              child: _editing == _CompanyEditField.domain
                  ? _InlineField(
                      controller: _editCtrl,
                      onSave: _save,
                      onCancel: _cancel,
                    )
                  : GestureDetector(
                      onDoubleTap: () =>
                          _startEditing(_CompanyEditField.domain),
                      child: Text(
                        company.domain ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.tertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Industry
            Expanded(
              flex: 2,
              child: _editing == _CompanyEditField.industry
                  ? _InlineField(
                      controller: _editCtrl,
                      onSave: _save,
                      onCancel: _cancel,
                    )
                  : GestureDetector(
                      onDoubleTap: () =>
                          _startEditing(_CompanyEditField.industry),
                      child: Text(
                        company.industry ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Phone
            Expanded(
              flex: 2,
              child: _editing == _CompanyEditField.phone
                  ? _InlineField(
                      controller: _editCtrl,
                      onSave: _save,
                      onCancel: _cancel,
                    )
                  : GestureDetector(
                      onDoubleTap: () =>
                          _startEditing(_CompanyEditField.phone),
                      child: Text(
                        company.phone ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Tags (compact, max 2)
            if (company.tags.isNotEmpty) ...[
              ...company.tags.take(2).map((tag) {
                final tagColor = _colorForTag(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: tagColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: tagColor, fontSize: 10),
                    ),
                  ),
                );
              }),
              if (company.tags.length > 2)
                Text(
                  '+${company.tags.length - 2}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ] else
              const SizedBox.shrink(),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextField(
        controller: controller,
        autofocus: true,
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
