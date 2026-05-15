import 'package:cis_crm/features/pipeline/presentation/bloc/pipeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline')),
      body: BlocBuilder<PipelineBloc, PipelineState>(
        builder: (context, state) {
          return switch (state) {
            PipelineInitial() => const Center(child: Text('Select a pipeline')),
            PipelineLoading() =>
              const Center(child: CircularProgressIndicator()),
            PipelineLoaded(:final kanbanStages) => kanbanStages != null
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: kanbanStages.length,
                    itemBuilder: (context, index) {
                      final stage = kanbanStages[index];
                      return SizedBox(
                        width: 300,
                        child: Card(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  stage.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text('No records'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No kanban data')),
            PipelineError(:final message) => Center(child: Text(message)),
          };
        },
      ),
    );
  }
}
