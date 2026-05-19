import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ── Account ──
          _SectionHeader(title: l10n.account),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.profileTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: Text(l10n.integrationsTitle),
            subtitle: const Text('Google Workspace'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.integrations),
          ),
          const Divider(),

          // ── Tools ──
          _SectionHeader(title: l10n.tools),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Companies'),
            subtitle: const Text('Manage organizations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.companies),
          ),
          ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: Text(l10n.automationTitle),
            subtitle: Text(l10n.automationSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.automation),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(l10n.emailCompose),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.emailCompose),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.emailTemplatesTitle),
            subtitle: Text(l10n.emailTemplatesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.emailTemplates),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(l10n.callLogTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.callLogs),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.filesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.files),
          ),
          const Divider(),

          // ── Configuration ──
          _SectionHeader(title: 'Configuration'),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Field Definitions'),
            subtitle: const Text('Custom fields for entities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.fieldDefinitions),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Tags'),
            subtitle: const Text('Manage tag taxonomy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.tags),
          ),
          ListTile(
            leading: const Icon(Icons.view_list_outlined),
            title: const Text('Saved Views'),
            subtitle: const Text('Custom list filters'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.savedViews),
          ),
          ListTile(
            leading: const Icon(Icons.draw_outlined),
            title: const Text('Email Signature'),
            subtitle: const Text('Organization email signature'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.emailSignature),
          ),
          const Divider(),

          // ── Admin ──
          _SectionHeader(title: 'Admin'),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Users'),
            subtitle: const Text('Manage team members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.users),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Audit Log'),
            subtitle: const Text('Track changes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.auditLog),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Import / Export'),
            subtitle: const Text('CSV data import and export'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.importExport),
          ),
          const Divider(),

          // ── Sign out ──
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.signOut,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
