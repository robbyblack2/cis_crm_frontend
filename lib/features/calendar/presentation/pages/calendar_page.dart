import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:cis_crm/features/calendar/presentation/pages/event_detail_page.dart';
import 'package:cis_crm/features/calendar/presentation/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CalendarBloc>()..add(const CalendarLoadRequested()),
      child: const _CalendarView(),
    );
  }
}

enum _CalendarViewMode { day, week, month }

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  _CalendarViewMode _viewMode = _CalendarViewMode.week;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        return switch (state) {
          CalendarInitial() ||
          CalendarLoading() =>
            const PageLoading(label: 'Loading calendar...'),
          CalendarError(:final failure) => PageError(
              title: 'Failed to load calendar',
              message: failure.message,
              onRetry: () => context
                  .read<CalendarBloc>()
                  .add(const CalendarLoadRequested()),
            ),
          CalendarLoaded(:final events) => _buildLoaded(context, events),
        };
      },
    );
  }

  Widget _buildLoaded(BuildContext context, List<CalendarEvent> events) {
    final grouped = _groupByDate(events);
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Go to today',
            onPressed: () {
              // TODO(feature): Scroll to today's date.
            },
            icon: const Icon(Icons.today),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_CalendarViewMode>(
              segments: const [
                ButtonSegment(
                  value: _CalendarViewMode.day,
                  label: Text('Day'),
                ),
                ButtonSegment(
                  value: _CalendarViewMode.week,
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: _CalendarViewMode.month,
                  label: Text('Month'),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) {
                setState(() => _viewMode = selection.first);
              },
            ),
          ),
        ),
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_month,
              title: 'No events',
              message: 'Tap + to create your first event.',
            )
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dateEvents = grouped[date]!;
                return _DateSection(
                  date: date,
                  events: dateEvents,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create event',
        onPressed: () {
          // TODO(nav): Navigate to event creation form.
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupByDate(
    List<CalendarEvent> events,
  ) {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final dateKey = DateTime(
        event.start.year,
        event.start.month,
        event.start.day,
      );
      (map[dateKey] ??= []).add(event);
    }
    return map;
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({required this.date, required this.events});

  final DateTime date;
  final List<CalendarEvent> events;

  String _formatDate(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, $month ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            _formatDate(date),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...events.map(
          (event) => EventTile(
            event: event,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailPage(event: event),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
