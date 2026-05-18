import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO(auth): replace placeholders with AuthBloc state once available.
    const displayName = 'CRM User';
    const email = 'user@example.com';
    const role = 'Admin';
    const initials = 'CU';

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
          const Center(
            child: Chip(label: Text(role)),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: AppLocalizations.of(context)!.security),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(AppLocalizations.of(context)!.changePassword),
            subtitle: Text(AppLocalizations.of(context)!.comingSoon),
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: AppLocalizations.of(context)!.preferences),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(AppLocalizations.of(context)!.timezone),
            subtitle: Text(AppLocalizations.of(context)!.comingSoon),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(AppLocalizations.of(context)!.calendarFilters),
            subtitle: Text(AppLocalizations.of(context)!.comingSoon),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
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
