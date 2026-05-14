/// Centralized route path constants.
///
/// Bloc-verifier rule: any string literal matching `r'^/[a-z]'` outside
/// this file, the router config, and tests is a violation. All `context.go(...)`
/// / `context.push(...)` calls reference [Routes] members, not bare strings.
///
/// `go_router_builder` is intentionally NOT used (avoids a second codegen
/// pipeline). Parameterized routes are typed via static methods, e.g.
/// `Routes.product('abc')`.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const forceUpgrade = '/force_upgrade';

  // App shell tabs (StatefulShellRoute branches)
  static const search = '/search';
  static const profile = '/profile';
  static const settings = '/settings';

  // Dev-only
  static const debugFlags = '/debug/flags';

  // Parameterized
  static String product(String id) => '/product/$id';
}
