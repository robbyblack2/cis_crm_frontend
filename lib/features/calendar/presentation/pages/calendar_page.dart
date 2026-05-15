import 'package:cis_crm/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:cis_crm/features/calendar/presentation/widgets/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          return switch (state) {
            CalendarInitial() => const Center(
                child: Text('Press load to fetch events'),
              ),
            CalendarLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            CalendarLoaded(:final events) => events.isEmpty
                ? const Center(child: Text('No events'))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) =>
                        EventTile(event: events[index]),
                  ),
            CalendarError(:final failure) => Center(
                child: Text(failure.message),
              ),
          };
        },
      ),
    );
  }
}
