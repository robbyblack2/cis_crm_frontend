import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_cubit.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IntegrationsPage extends StatelessWidget {
  const IntegrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoogleIntegrationCubit>()..loadStatus(),
      child: const _IntegrationsView(),
    );
  }
}

class _IntegrationsView extends StatelessWidget {
  const _IntegrationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GoogleIntegrationCard(),
        ],
      ),
    );
  }
}

class _GoogleIntegrationCard extends StatelessWidget {
  const _GoogleIntegrationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<GoogleIntegrationCubit, GoogleIntegrationState>(
      listener: (context, state) {
        if (state is GoogleIntegrationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.failure.message)),
          );
        }
      },
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Workspace',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'Connect Gmail, Calendar, and Contacts',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(state),
                  ],
                ),
                const SizedBox(height: 16),
                if (state is GoogleIntegrationLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is GoogleIntegrationLoaded &&
                    state.connection.connected) ...[
                  _buildConnectedInfo(context, state),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<GoogleIntegrationCubit>()
                        .disconnectGoogle(),
                    child: const Text('Disconnect'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () => _handleConnect(context),
                    icon: const Icon(Icons.link),
                    label: const Text('Connect Google Account'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(GoogleIntegrationState state) {
    if (state is GoogleIntegrationLoaded && state.connection.connected) {
      return const Chip(
        label: Text('Connected'),
        backgroundColor: Color(0xFFE8F5E9),
        side: BorderSide.none,
      );
    }
    return const Chip(
      label: Text('Not connected'),
      side: BorderSide.none,
    );
  }

  Widget _buildConnectedInfo(
    BuildContext context,
    GoogleIntegrationLoaded state,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.connection.email != null)
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 16),
              const SizedBox(width: 8),
              Text(state.connection.email!, style: theme.textTheme.bodyMedium),
            ],
          ),
        if (state.connection.lastSync != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.sync, size: 16),
              const SizedBox(width: 8),
              Text(
                'Last synced: ${_formatDateTime(state.connection.lastSync!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleConnect(BuildContext context) async {
    final cubit = context.read<GoogleIntegrationCubit>();
    final authUrl = await cubit.connectGoogle();
    if (authUrl == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Google Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Copy the link below and open it in your browser to '
              'authorize your Google account:',
            ),
            const SizedBox(height: 12),
            SelectableText(
              authUrl,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              unawaited(
                Clipboard.setData(ClipboardData(text: authUrl)).then((_) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  }
                }),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );

    // Reload status after dialog closes (user may have completed OAuth).
    unawaited(cubit.loadStatus());
  }
}
