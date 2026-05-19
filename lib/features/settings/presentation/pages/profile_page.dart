import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final authState = getIt<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final displayName =
        user != null && user.displayName.isNotEmpty ? user.displayName : '—';
    final email = user?.email ?? '—';
    final role = user?.status.name ?? '—';
    final initials = _computeInitials(displayName);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              displayName,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Chip(label: Text(role)),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: AppLocalizations.of(context)!.security),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(AppLocalizations.of(context)!.changePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: AppLocalizations.of(context)!.preferences),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(AppLocalizations.of(context)!.timezone),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPreferenceDialog(
              context,
              'timezone',
              AppLocalizations.of(context)!.timezone,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(AppLocalizations.of(context)!.calendarFilters),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPreferenceDialog(
              context,
              'calendar_default_view',
              AppLocalizations.of(context)!.calendarFilters,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              decoration:
                  const InputDecoration(labelText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              decoration:
                  const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              decoration:
                  const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                final authState = getIt<AuthBloc>().state;
                final userId = authState is AuthAuthenticated
                    ? authState.user.id
                    : '';
                await getIt<Dio>().put<void>(
                  '/api/users/$userId/password',
                  data: {
                    'current_password': currentCtrl.text,
                    'new_password': newCtrl.text,
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(ctx)!.save),
          ),
        ],
      ),
    );
  }

  void _showPreferenceDialog(
    BuildContext context,
    String key,
    String label,
  ) {
    final ctrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            hintText: key == 'timezone'
                ? 'e.g. America/New_York'
                : 'e.g. week',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<Dio>().put<void>(
                  '/api/users/me/preferences',
                  data: {key: ctrl.text.trim()},
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(ctx)!.save),
          ),
        ],
      ),
    );
  }

  static String _computeInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
