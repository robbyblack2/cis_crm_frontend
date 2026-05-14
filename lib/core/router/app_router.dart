import 'dart:async';

import 'package:cis_crm/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
