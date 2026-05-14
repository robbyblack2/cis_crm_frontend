import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/injection.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../bloc/example_bloc.dart';
import '../widgets/example_tile.dart';

/// Page-level entry for the `example` feature.
///
/// Provides the [ExampleBloc] from `getIt` (factory-scoped — fresh instance
/// per mount) and immediately dispatches the initial load. The view is split
/// into a separate widget so it can read the bloc via `context`.
class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExampleBloc>(
      create: (_) => getIt<ExampleBloc>()..add(const ExampleLoadRequested()),
      child: const _ExampleView(),
    );
  }
}

class _ExampleView extends StatelessWidget {
  const _ExampleView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      body: BlocBuilder<ExampleBloc, ExampleState>(
        builder: (context, state) {
          return switch (state) {
            ExampleInitial() || ExampleLoading() => const LoadingView(),
            ExampleLoaded(:final items) when items.isEmpty => EmptyState(
                title: 'No examples yet',
                message: 'Tap + to add your first one.',
                action: FilledButton.icon(
                  onPressed: () =>
                      _showCreateSheet(context.read<ExampleBloc>()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add example'),
                ),
              ),
            ExampleLoaded(:final items) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ExampleBloc>()
                      .add(const ExampleRefreshRequested());
                },
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => ExampleTile(item: items[i]),
                ),
              ),
            ExampleError(:final failure) => ErrorView(
                failure: failure,
                onRetry: () => context
                    .read<ExampleBloc>()
                    .add(const ExampleLoadRequested()),
              ),
          };
        },
      ),
      floatingActionButton: BlocBuilder<ExampleBloc, ExampleState>(
        buildWhen: (a, b) => (a is ExampleLoaded) != (b is ExampleLoaded),
        builder: (context, state) {
          if (state is! ExampleLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showCreateSheet(context.read<ExampleBloc>()),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showCreateSheet(ExampleBloc bloc) {
    // Real impl: show a bottom sheet with form, dispatch ExampleCreateRequested.
    // Placeholder no-op so the template compiles.
  }
}
