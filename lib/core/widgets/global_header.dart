import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Global top navigation bar shown above all page content.
///
/// Contains: app branding, global search (Ctrl+K), compose email,
/// and profile menu.
class GlobalHeader extends StatelessWidget {
  const GlobalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
        children: [
          // App branding
          InkWell(
            onTap: () => context.go(Routes.home),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'CIS CRM',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Global search
          Expanded(
            child: _GlobalSearchBar(
              onTap: () => context.push(Routes.search),
            ),
          ),
          const SizedBox(width: 16),

          // Compose email
          FilledButton.tonalIcon(
            onPressed: () => context.push(Routes.emailCompose),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Compose'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 8),

          // Profile menu
          _ProfileMenu(),
        ],
      ),
      ),
    );
  }
}

class _GlobalSearchBar extends StatelessWidget {
  const _GlobalSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  'Ctrl+K',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Try to get user info from auth state
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? (authState.user.displayName.isNotEmpty
            ? authState.user.displayName
            : authState.user.email)
        : 'Account';
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 40),
      onSelected: (action) {
        switch (action) {
          case 'profile':
            context.push(Routes.profile);
          case 'settings':
            context.push(Routes.settings);
          case 'logout':
            context.read<AuthBloc>().add(const AuthSignOutRequested());
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (authState is AuthAuthenticated)
                Text(authState.user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 18,
              color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
