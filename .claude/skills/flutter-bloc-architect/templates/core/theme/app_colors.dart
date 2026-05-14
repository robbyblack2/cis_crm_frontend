import 'package:flutter/material.dart';

/// Brand seed + semantic colors not covered by `ColorScheme`.
///
/// Material 3's `ColorScheme.fromSeed` derives the full palette (primary,
/// secondary, tertiary, container, on*, error, surface, outline...) from a
/// single seed color, generating WCAG-compliant contrast pairs for both
/// brightness modes automatically. See `references/theming.md`.
///
/// Override `seed` per project to rebrand. Everything else flows from it.
abstract final class AppColors {
  /// Brand seed. Material 3 generates the full ColorScheme from this.
  static const seed = Color(0xFF6750A4);

  /// Semantic colors not in `ColorScheme`. Read via a `ThemeExtension` or
  /// directly when there's no scheme equivalent.
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFEF6C00);
  static const info = Color(0xFF0277BD);
}
