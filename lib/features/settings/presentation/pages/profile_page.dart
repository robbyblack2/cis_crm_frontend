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
      appBar: AppBar(title: const Text('Profile')),
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
          const _SectionHeader(title: 'Security'),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Change Password'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Preferences'),
          const ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Timezone'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Calendar Filters'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.chevron_right),
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
