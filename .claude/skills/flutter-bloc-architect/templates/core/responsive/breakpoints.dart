/// Material 3 canonical breakpoints.
///
/// Used by [AdaptiveScaffold] and any page-level `LayoutBuilder` that
/// needs to switch between phone / tablet / desktop layouts.
abstract final class Breakpoints {
  /// Phone (portrait or small landscape).
  static const compact = 600.0;

  /// Tablet portrait, foldable open, small desktop window.
  static const medium = 840.0;

  /// Tablet landscape, desktop, large window.
  static const expanded = 1200.0;
}

/// Categorical width bucket for picking layout primitives.
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeFor(double width) {
  if (width >= Breakpoints.expanded) return WindowSize.expanded;
  if (width >= Breakpoints.compact) return WindowSize.medium;
  return WindowSize.compact;
}
