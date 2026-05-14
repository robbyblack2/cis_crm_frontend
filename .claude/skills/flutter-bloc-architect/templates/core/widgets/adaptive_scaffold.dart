import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../responsive/breakpoints.dart';

/// Adaptive scaffold powered by `StatefulShellRoute.indexedStack`.
///
/// Picks the navigation surface by viewport width:
///   - compact (<600dp)  → `NavigationBar` at bottom (phone)
///   - medium (600–840)  → `NavigationRail` on the left (tablet portrait)
///   - expanded (≥840)   → `NavigationDrawer` open permanently (desktop)
///
/// All three drive the same `StatefulShellRoute` — only the rendering
/// differs. Per-tab navigation state survives tab switches because each
/// branch has its own `Navigator`.
///
/// Pass [destinations] in the same order as the `StatefulShellRoute`
/// branches in `app_router.dart`.
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
        return switch (size) {
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
        onDestinationSelected: onTap,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
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
            onDestinationSelected: onTap,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text(''),
              ),
              for (final d in destinations)
                NavigationDrawerDestination(
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
