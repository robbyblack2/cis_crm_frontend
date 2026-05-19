import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/widgets/record_card.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Color _parseColor(String colorStr) {
  if (colorStr.startsWith('#')) {
    final hex = colorStr.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
  return Color(int.tryParse(colorStr) ?? 0xFF9E9E9E);
}

class StageColumn extends StatelessWidget {
  const StageColumn({
    required this.stage,
    required this.records,
    required this.onRecordTap,
    super.key,
  });

  final Stage stage;
  final List<PipelineRecord> records;
  final ValueChanged<PipelineRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageColor = _parseColor(stage.color);

    return DragTarget<PipelineRecord>(
      onWillAcceptWithDetails: (details) =>
          details.data.stageId != stage.id,
      onAcceptWithDetails: (details) {
        context.read<RecordBloc>().add(
              RecordMoveRequested(
                recordId: details.data.id,
                toStageId: stage.id,
              ),
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stage header ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isHovering
                      ? stageColor.withValues(alpha: 0.3)
                      : stageColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stageColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stage.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${records.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stageColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Records list ──
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? stageColor.withValues(alpha: 0.08)
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: isHovering
                        ? Border.all(
                            color: stageColor.withValues(alpha: 0.4),
                            width: 2,
                          )
                        : null,
                  ),
                  child: records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              isHovering
                                  ? AppLocalizations.of(context)!
                                      .dropHere
                                  : AppLocalizations.of(context)!
                                      .noRecords,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return _DraggableRecordCard(
                              record: record,
                              onTap: () => onRecordTap(record),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableRecordCard extends StatelessWidget {
  const _DraggableRecordCard({
    required this.record,
    required this.onTap,
  });

  final PipelineRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<PipelineRecord>(
      data: record,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 280,
          child: Opacity(
            opacity: 0.9,
            child: RecordCard(record: record, onTap: () {}),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: RecordCard(record: record, onTap: () {}),
      ),
      child: RecordCard(record: record, onTap: onTap),
    );
  }
}
