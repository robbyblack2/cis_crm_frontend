import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/example_entity.dart';
import '../bloc/example_bloc.dart';

/// Feature-local widget for one [ExampleEntity] row.
class ExampleTile extends StatelessWidget {
  const ExampleTile({required this.item, super.key});

  final ExampleEntity item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: item.description != null ? Text(item.description!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context
            .read<ExampleBloc>()
            .add(ExampleDeleteRequested(item.id)),
      ),
    );
  }
}
