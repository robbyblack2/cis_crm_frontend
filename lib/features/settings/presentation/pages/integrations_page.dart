import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_cubit.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_state.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.integrationsTitle),
      ),
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
                            AppLocalizations.of(context)!.googleWorkspace,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            AppLocalizations.of(context)!
                                .googleWorkspaceDescription,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(context, state),
                  ],
                ),
                const SizedBox(height: 16),
                if (state is GoogleIntegrationLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Waiting for authorization...'),
                        ],
                      ),
                    ),
                  )
                else if (state is GoogleIntegrationLoaded &&
                    state.connection.connected) ...[
                  _buildConnectedInfo(context, state),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<GoogleIntegrationCubit>()
                        .disconnectGoogle(),
                    child: Text(
                        AppLocalizations.of(context)!.disconnect),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () => _handleConnect(context),
                    icon: const Icon(Icons.link),
                    label: Text(
                      AppLocalizations.of(context)!.connectGoogleAccount,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
      BuildContext context, GoogleIntegrationState state) {
    if (state is GoogleIntegrationLoaded && state.connection.connected) {
      return Chip(
        label: Text(AppLocalizations.of(context)!.connected),
        backgroundColor: const Color(0xFFE8F5E9),
        side: BorderSide.none,
      );
    }
    return Chip(
      label: Text(AppLocalizations.of(context)!.notConnected),
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
              Text(state.connection.email!,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        if (state.connection.lastSync != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.sync, size: 16),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.lastSynced(
                    _formatDateTime(state.connection.lastSync!)),
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

    // Try to open URL directly in browser
    final uri = Uri.parse(authUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      // Fallback: show URL to copy
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(ctx)!.connectGoogleAccount,
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(ctx)!.connectGoogleInstructions),
              const SizedBox(height: 12),
              SelectableText(
                authUrl,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  unawaited(
                    Clipboard.setData(ClipboardData(text: authUrl))
                        .then((_) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(ctx)!.linkCopied),
                          ),
                        );
                      }
                    }),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(AppLocalizations.of(ctx)!.copyLink),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done — I completed the authorization'),
              ),
            ],
          ),
        ),
      );
    }

    // Poll for connection status after OAuth
    if (context.mounted) {
      unawaited(cubit.pollUntilConnected());
    }
  }
}
