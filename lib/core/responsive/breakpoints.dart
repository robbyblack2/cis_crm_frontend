abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1200.0;
}

enum WindowSize { compact, medium, expanded }

WindowSize windowSizeFor(double width) {
  if (width >= Breakpoints.expanded) return WindowSize.expanded;
  if (width >= Breakpoints.compact) return WindowSize.medium;
  return WindowSize.compact;
}
