abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const forceUpgrade = '/force_upgrade';

  static const search = '/search';
  static const profile = '/profile';
  static const settings = '/settings';

  static const debugFlags = '/debug/flags';

  static String product(String id) => '/product/$id';
}
