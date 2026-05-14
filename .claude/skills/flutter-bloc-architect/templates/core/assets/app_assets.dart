/// Centralized asset path constants.
///
/// Bloc-verifier rule: any string literal matching `r'^assets/.+'` outside
/// this file and `pubspec.yaml` is a violation. Add new asset paths here,
/// then reference them from widgets via `AppAssets.foo`.
abstract final class AppAssets {
  // Build inputs (consumed by flutter_launcher_icons / flutter_native_splash —
  // not bundled with the app):
  static const launcherIcon = 'assets/launcher_icon.png';
  static const launcherIconForeground = 'assets/launcher_icon_foreground.png';
  static const splash = 'assets/splash.png';

  // In-app images (paths inside assets/images/, assets/icons/, assets/lottie/):
  // static const logo = 'assets/images/logo.png';
}
