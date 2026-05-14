import 'package:go_router/go_router.dart';

import '../widgets/adaptive_scaffold.dart';

/// Helper for declaring the bottom-nav / rail / drawer shell route.
///
/// Wraps `StatefulShellRoute.indexedStack` so each branch keeps its own
/// `Navigator` (per-tab state survives tab switches) and the shell
/// renders via `AdaptiveScaffold` (NavigationBar / Rail / Drawer by
/// viewport width).
RouteBase buildAdaptiveShell({
  required List<AdaptiveDestination> destinations,
  required List<StatefulShellBranch> branches,
}) {
  assert(
    destinations.length == branches.length,
    'destinations and branches must be the same length',
  );
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AdaptiveScaffold(
      navigationShell: navigationShell,
      destinations: destinations,
    ),
    branches: branches,
  );
}
