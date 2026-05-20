import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/bloc/record_bloc.dart';
import 'package:cis_crm/features/pipeline/presentation/widgets/record_card.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

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
        _handleMoveWithPrompts(
          context,
          details.data,
          stage,
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
                              currentStageId: stage.id,
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

  static Future<void> _handleMoveWithPrompts(
    BuildContext context,
    PipelineRecord record,
    Stage targetStage,
  ) async {
    // Check if the target stage has prompts configured
    List<Map<String, dynamic>> prompts;
    try {
      prompts = await GetIt.instance<PipelineRemoteDataSource>()
          .getStagePrompts(targetStage.id);
    } catch (_) {
      prompts = [];
    }

    if (prompts.isEmpty) {
      // No prompts — move directly
      if (!context.mounted) return;
      context.read<RecordBloc>().add(
            RecordMoveRequested(
              recordId: record.id,
              toStageId: targetStage.id,
            ),
          );
      return;
    }

    // Show prompt bottom sheet
    if (!context.mounted) return;
    final promptData = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      builder: (ctx) => _StagePromptSheet(
        stageName: targetStage.name,
        stageColor: targetStage.color,
        prompts: prompts,
      ),
    );

    if (promptData == null || !context.mounted) return;

    context.read<RecordBloc>().add(
          RecordMoveRequested(
            recordId: record.id,
            toStageId: targetStage.id,
            promptData: promptData,
          ),
        );
  }
}

class _StagePromptSheet extends StatefulWidget {
  const _StagePromptSheet({
    required this.stageName,
    required this.stageColor,
    required this.prompts,
  });

  final String stageName;
  final String stageColor;
  final List<Map<String, dynamic>> prompts;

  @override
  State<_StagePromptSheet> createState() => _StagePromptSheetState();
}

class _StagePromptSheetState extends State<_StagePromptSheet> {
  final _values = <String, String>{};

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Color(int.tryParse(colorStr) ?? 0xFF9E9E9E);
  }

  String _humanizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stageColor = _parseColor(widget.stageColor);

    final sortedPrompts = [...widget.prompts]
      ..sort(
        (a, b) =>
            (a['sort_order'] as int? ?? 0)
                .compareTo(b['sort_order'] as int? ?? 0),
      );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with stage color
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stageColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Move to ${widget.stageName}',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Please fill in the required information before moving this record.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Prompt fields
            for (final prompt in sortedPrompts) ...[
              _buildPromptField(prompt),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      for (final prompt in sortedPrompts) {
                        final isRequired =
                            prompt['is_required'] as bool? ?? false;
                        final fieldDef = prompt['field_definition']
                                as Map<String, dynamic>? ??
                            prompt;
                        final key = fieldDef['field_key'] as String? ??
                            fieldDef['id'] as String? ??
                            '';
                        if (isRequired &&
                            (_values[key]?.isEmpty ?? true)) {
                          final name = fieldDef['display_name'] as String? ??
                              fieldDef['name'] as String? ??
                              _humanizeKey(key);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name is required')),
                          );
                          return;
                        }
                      }
                      Navigator.pop(context, _values);
                    },
                    child: const Text('Move'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptField(Map<String, dynamic> prompt) {
    final fieldDef =
        prompt['field_definition'] as Map<String, dynamic>? ?? prompt;
    final key = fieldDef['field_key'] as String? ??
        fieldDef['id'] as String? ??
        '';
    final name = fieldDef['display_name'] as String? ??
        fieldDef['name'] as String? ??
        _humanizeKey(key);
    final fieldType = fieldDef['field_type'] as String? ?? 'text';
    final isRequired = prompt['is_required'] as bool? ?? false;
    final options = fieldDef['options'] as List<dynamic>?;

    final label = '$name${isRequired ? ' *' : ''}';

    if (fieldType == 'dropdown' && options != null) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((o) {
          // Handle both string options and {value, label} objects
          if (o is Map<String, dynamic>) {
            final value = o['value'] as String? ?? '';
            final optLabel = o['label'] as String? ??
                o['display_name'] as String? ??
                o['name'] as String? ??
                value;
            return DropdownMenuItem(value: value, child: Text(optLabel));
          }
          final str = o.toString();
          return DropdownMenuItem(
            value: str,
            child: Text(_humanizeKey(str)),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) _values[key] = v;
        },
      );
    }

    if (fieldType == 'checkbox' || fieldType == 'boolean') {
      return CheckboxListTile(
        title: Text(label),
        value: _values[key] == 'true',
        onChanged: (v) {
          setState(() => _values[key] = (v ?? false).toString());
        },
        contentPadding: EdgeInsets.zero,
      );
    }

    if (fieldType == 'textarea' || fieldType == 'text_area') {
      return TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (v) => _values[key] = v,
      );
    }

    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: fieldType == 'number' || fieldType == 'currency'
          ? TextInputType.number
          : fieldType == 'email'
              ? TextInputType.emailAddress
              : TextInputType.text,
      onChanged: (v) => _values[key] = v,
    );
  }
}

class _DraggableRecordCard extends StatelessWidget {
  const _DraggableRecordCard({
    required this.record,
    required this.onTap,
    required this.currentStageId,
  });

  final PipelineRecord record;
  final VoidCallback onTap;
  final String currentStageId;

  void _showMoveMenu(BuildContext context) {
    final pipelineState =
        context.read<PipelineBloc>().state;
    if (pipelineState is! PipelineLoaded) return;
    final stages = pipelineState.kanbanStages ?? [];
    if (stages.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Move to stage',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...stages.map(
              (s) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(s.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(s.name),
                enabled: s.id != currentStageId,
                trailing: s.id == currentStageId
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<RecordBloc>().add(
                        RecordMoveRequested(
                          recordId: record.id,
                          toStageId: s.id,
                        ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<PipelineRecord>(
      delay: const Duration(milliseconds: 150),
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
      child: RecordCard(
        record: record,
        onTap: onTap,
        onMoveStage: () => _showMoveMenu(context),
      ),
    );
  }
}
