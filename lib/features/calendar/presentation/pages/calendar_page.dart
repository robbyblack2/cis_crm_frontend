import 'dart:async';

import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/network/web_socket_cubit.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:cis_crm/features/calendar/presentation/pages/event_detail_page.dart';
import 'package:cis_crm/features/calendar/presentation/widgets/event_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

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

/// Calendar event types that trigger a reload.
const _calendarEventTypes = {
  'calendar.event_created',
  'calendar.event_updated',
  'calendar.event_deleted',
  'calendar.synced',
};

class _CalendarViewState extends State<_CalendarView> {
  _CalendarViewMode _viewMode = _CalendarViewMode.week;
  bool _showGrid = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  StreamSubscription<WebSocketEvent>? _wsSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _subscribeToWebSocket();
    // Periodic refresh every 30s to pick up Google Calendar syncs
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          context
              .read<CalendarBloc>()
              .add(const CalendarLoadRequested());
        }
      },
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pollTimer?.cancel();
    _unsubscribeChannel();
    super.dispose();
  }

  void _subscribeToWebSocket() {
    try {
      final wsCubit = context.read<WebSocketCubit>()
        ..subscribe('calendar');

      _wsSub = wsCubit.events.listen((event) {
        if (_calendarEventTypes.contains(event.type) && mounted) {
          context
              .read<CalendarBloc>()
              .add(const CalendarLoadRequested());
        }
      });
    } catch (_) {
      // WebSocket may not be connected — polling handles it
    }
  }

  void _unsubscribeChannel() {
    try {
      context.read<WebSocketCubit>().unsubscribe('calendar');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        return switch (state) {
          CalendarInitial() ||
          CalendarLoading() =>
            PageLoading(label: AppLocalizations.of(context)!.calendarLoading),
          CalendarError(:final failure) => PageError(
              title: AppLocalizations.of(context)!.failedToLoadCalendar,
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

  Future<void> _showCreateEventDialog(BuildContext context) async {
    final titleController = TextEditingController();
    var startDate = DateTime.now();
    var endDate = DateTime.now().add(const Duration(hours: 1));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.createEvent),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(dialogContext)!.title,
                    hintText: AppLocalizations.of(dialogContext)!.enterEventTitle,
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(dialogContext)!.start),
                  subtitle: Text(
                    _formatDateTime(startDate),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date == null || !dialogContext.mounted) return;
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(startDate),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      startDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      if (endDate.isBefore(startDate)) {
                        endDate = startDate.add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(dialogContext)!.end),
                  subtitle: Text(
                    _formatDateTime(endDate),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2100),
                    );
                    if (date == null || !dialogContext.mounted) return;
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(endDate),
                    );
                    if (time == null) return;
                    setDialogState(() {
                      endDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final event = CalendarEvent(
                  id: '',
                  title: title,
                  start: startDate,
                  end: endDate,
                  createdAt: DateTime.now(),
                );
                context
                    .read<CalendarBloc>()
                    .add(CalendarEventCreateRequested(event: event));
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(dialogContext)!.create),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  List<CalendarEvent> _filterByViewMode(List<CalendarEvent> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_viewMode) {
      _CalendarViewMode.day => events
          .where(
            (e) =>
                e.start.year == today.year &&
                e.start.month == today.month &&
                e.start.day == today.day,
          )
          .toList(),
      _CalendarViewMode.week => events.where((e) {
          final weekStart =
              today.subtract(Duration(days: today.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          return !e.start.isBefore(weekStart) && e.start.isBefore(weekEnd);
        }).toList(),
      _CalendarViewMode.month => events
          .where(
            (e) =>
                e.start.year == today.year && e.start.month == today.month,
          )
          .toList(),
    };
  }

  Widget _buildLoaded(BuildContext context, List<CalendarEvent> events) {
    final eventMap = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final key = DateTime(event.start.year, event.start.month, event.start.day);
      (eventMap[key] ??= []).add(event);
    }

    final selectedKey = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    final dayEvents = eventMap[selectedKey] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.calendarTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.goToToday,
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
            icon: const Icon(Icons.today),
          ),
          IconButton(
            tooltip: _showGrid ? 'List view' : 'Calendar view',
            onPressed: () => setState(() => _showGrid = !_showGrid),
            icon: Icon(_showGrid ? Icons.list : Icons.calendar_month),
          ),
        ],
      ),
      body: _showGrid
          ? Column(
              children: [
                TableCalendar<CalendarEvent>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  calendarFormat: _viewMode == _CalendarViewMode.month
                      ? CalendarFormat.month
                      : CalendarFormat.week,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) => setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  }),
                  onFormatChanged: (format) => setState(() {
                    _viewMode = format == CalendarFormat.month
                        ? _CalendarViewMode.month
                        : _CalendarViewMode.week;
                  }),
                  onPageChanged: (focusedDay) =>
                      _focusedDay = focusedDay,
                  rowHeight: 80,
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return eventMap[key] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 0,
                    cellMargin: const EdgeInsets.all(2),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    defaultDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    weekendDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    outsideDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (ctx, date, events) {
                      if (events.isEmpty) return null;
                      return Positioned(
                        bottom: 2,
                        left: 2,
                        right: 2,
                        child: Column(
                          children: events
                              .take(2)
                              .map(
                                (e) => Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: dayEvents.isEmpty
                      ? Center(
                          child: Text(
                            'No events on this day',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: dayEvents.length,
                          itemBuilder: (context, index) {
                            final event = dayEvents[index];
                            return EventTile(
                              event: event,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      EventDetailPage(event: event),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : _buildListView(context, events),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        tooltip: AppLocalizations.of(context)!.createEventTooltip,
        onPressed: () => _showCreateEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<CalendarEvent> events) {
    final filtered = _filterByViewMode(events);
    final grouped = _groupByDate(filtered);
    final sortedDates = grouped.keys.toList()..sort();
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_month,
        title: AppLocalizations.of(context)!.noEvents,
        message: AppLocalizations.of(context)!.noEventsMessage,
      );
    }
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        return _DateSection(date: date, events: grouped[date]!);
      },
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
