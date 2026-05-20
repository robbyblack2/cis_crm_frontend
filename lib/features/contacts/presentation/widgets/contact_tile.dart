import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:flutter/material.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({
    required this.contact,
    this.onTap,
    super.key,
  });

  final Contact contact;
  final VoidCallback? onTap;

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

  static const _tagColors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF14B8A6), Color(0xFF3B82F6),
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFF64748B), Color(0xFF78716C), Color(0xFF0EA5E9),
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
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(contact.status);

    return InkWell(
      onTap: onTap,
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
                  if (contact.jobTitle != null &&
                      contact.jobTitle!.isNotEmpty)
                    Text(
                      contact.jobTitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Email
            Expanded(
              flex: 3,
              child: Text(
                contact.email,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Phone
            if (contact.phone != null && contact.phone!.isNotEmpty)
              Expanded(
                flex: 2,
                child: Text(
                  contact.phone!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Expanded(flex: 2, child: SizedBox.shrink()),
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

            // Status badge
            Container(
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

            // Tags (compact, max 2)
            if (contact.tags.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...contact.tags.take(2).map((tag) {
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
                      border: Border.all(
                        color: tagColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tagColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }),
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
