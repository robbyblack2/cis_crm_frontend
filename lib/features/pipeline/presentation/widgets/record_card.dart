import 'package:cis_crm/core/utils/name_resolver.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:flutter/material.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({
    required this.record,
    required this.onTap,
    this.onEmail,
    this.onAddNote,
    this.onMoveStage,
    super.key,
  });

  final PipelineRecord record;
  final VoidCallback onTap;
  final VoidCallback? onEmail;
  final VoidCallback? onAddNote;
  final VoidCallback? onMoveStage;

  IconData _sourceIcon(RecordSource source) => switch (source) {
        RecordSource.email => Icons.email_outlined,
        RecordSource.automation => Icons.smart_toy_outlined,
        RecordSource.syncRule => Icons.sync_outlined,
        RecordSource.manual => Icons.edit_outlined,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Color _stageAgeColor(DateTime updatedAt) {
    final days = DateTime.now().difference(updatedAt).inDays;
    if (days < 1) return Colors.green;
    if (days <= 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stageAge = DateTime.now().difference(record.updatedAt);
    final stageAgeLabel = stageAge.inDays > 0
        ? '${stageAge.inDays}d in stage'
        : stageAge.inHours > 0
            ? '${stageAge.inHours}h in stage'
            : 'Just moved';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title row with owner avatar ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (record.ownerId != null) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: record.ownerId ?? '',
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          record.ownerId!.isNotEmpty
                              ? record.ownerId![0].toUpperCase()
                              : '?',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // ── Source + stage age ──
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    _sourceIcon(record.source),
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.source.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Stage age indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _stageAgeColor(record.updatedAt)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stageAgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _stageAgeColor(record.updatedAt),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Sender email (for email-sourced records) ──
              if (record.senderEmail != null &&
                  record.senderEmail!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.alternate_email,
                      size: 14,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.senderEmail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.tertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Contact name ──
              if (record.contactId != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ResolvedName(
                        id: record.contactId,
                        type: 'contact',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Tags ──
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: record.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          labelStyle: theme.textTheme.labelSmall,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // ── Quick actions toolbar ──
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: Icons.email_outlined,
                    tooltip: 'Send email',
                    onTap: onEmail,
                  ),
                  _QuickAction(
                    icon: Icons.note_add_outlined,
                    tooltip: 'Add note',
                    onTap: onAddNote,
                  ),
                  _QuickAction(
                    icon: Icons.drive_file_move_outlined,
                    tooltip: 'Move stage',
                    onTap: onMoveStage,
                  ),
                ],
              ),

              // ── Created age ──
              const SizedBox(height: 4),
              Text(
                _timeAgo(record.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
