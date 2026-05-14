import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// The application router.
///
/// Auth gating is enforced at the top level via [redirect]. The router
/// rebuilds whenever `AuthRepository.status` emits — feed the repository
/// stream into [refreshListenable] (NOT `AuthBloc.stream`) so the gate
/// re-evaluates on cold start before the bloc has a chance to settle.
///
/// Redirect priority (highest first, per MEMORY Q16):
///   1. Force-upgrade required → /force_upgrade
///   2. Onboarding not seen   → /onboarding
///   3. Auth gate              → /login (unauthenticated visit to a
///       protected route) or / (authenticated visit to /login)
///   4. Otherwise no redirect.
///
/// `StatefulShellRoute.indexedStack` powers the bottom-nav / rail / drawer
/// shell — each branch keeps its own Navigator so per-tab state survives
/// tab switches. The `AdaptiveScaffold` widget at `lib/core/widgets/`
/// renders the nav surface based on viewport width.
///
/// Type safety: every `path:` value comes from [Routes]; bare string
/// literals matching `r'^/[a-z]'` outside this file and `routes.dart`
/// are bloc-verifier violations.
GoRouter buildAppRouter({
  required Stream<dynamic> authStatusStream,
  required GlobalKey<NavigatorState> navigatorKey,
  required FutureOr<String?> Function(BuildContext, GoRouterState) redirect,
  required List<RouteBase> routes,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(authStatusStream),
    redirect: redirect,
    routes: routes,
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
}

/// Bridges a `Stream<X>` into [Listenable] so [GoRouter.refreshListenable]
/// rebuilds on each emission.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
