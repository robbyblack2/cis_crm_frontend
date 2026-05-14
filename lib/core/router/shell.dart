import 'package:cis_crm/core/widgets/adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';

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
