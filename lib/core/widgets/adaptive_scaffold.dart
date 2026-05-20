import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:cis_crm/core/router/routes.dart';
import 'package:cis_crm/core/widgets/global_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.navigationShell,
    required this.destinations,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AdaptiveDestination> destinations;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = windowSizeFor(constraints.maxWidth);
        final showHeader = size != WindowSize.compact;
        final nav = switch (size) {
          WindowSize.compact => _Bottom(
              shell: navigationShell,
              destinations: destinations,
              onTap: _onTap,
            ),
          WindowSize.medium => _Rail(
              shell: navigationShell,
              destinations: destinations,
              onTap: _onTap,
            ),
          WindowSize.expanded => _Drawer(
              shell: navigationShell,
              destinations: destinations,
              onTap: _onTap,
            ),
        };
        if (!showHeader) return nav;
        return Column(
          children: [
            const GlobalHeader(),
            Expanded(child: nav),
          ],
        );
      },
    );
  }
}

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

class _Bottom extends StatelessWidget {
  const _Bottom({
    required this.shell,
    required this.destinations,
    required this.onTap,
  });

  final StatefulNavigationShell shell;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) {
          // Last two virtual destinations: Search and Settings
          if (index == destinations.length) {
            context.push(Routes.search);
            return;
          }
          if (index == destinations.length + 1) {
            context.push(Routes.settings);
            return;
          }
          onTap(index);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.shell,
    required this.destinations,
    required this.onTap,
  });

  final StatefulNavigationShell shell;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            leading: Column(
              children: [
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () => context.push(Routes.search),
                ),
                const SizedBox(height: 4),
              ],
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.push(Routes.settings),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.shell,
    required this.destinations,
    required this.onTap,
  });

  final StatefulNavigationShell shell;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) {
              if (index == destinations.length) {
                context.push(Routes.search);
                return;
              }
              if (index == destinations.length + 1) {
                context.push(Routes.settings);
                return;
              }
              onTap(index);
            },
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text('CIS CRM'),
              ),
              for (final d in destinations)
                NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
              const Divider(indent: 28, endIndent: 28),
              const NavigationDrawerDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
