import 'dart:ui';

/// Default fallback color used when a color string cannot be parsed.
const Color kFallbackColor = Color(0xFF9E9E9E);

/// Parses a color string that may be:
/// - A hex string with `#` prefix (e.g. `#FF5733`, `#80FF5733`)
/// - A hex string without prefix (e.g. `FF5733`)
/// - A raw integer string (e.g. `4294924595`)
///
/// Returns [fallback] (defaults to grey) when parsing fails.
Color parseHexColor(String colorStr, {Color fallback = kFallbackColor}) {
  final trimmed = colorStr.trim();
  if (trimmed.isEmpty) return fallback;

  // Strip leading #
  final hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;

  // 6-digit hex → prepend FF alpha
  if (hex.length == 6) {
    final value = int.tryParse('FF$hex', radix: 16);
    return value != null ? Color(value) : fallback;
  }

  // 8-digit hex → use as-is
  if (hex.length == 8) {
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : fallback;
  }

  // Raw integer string
  final intValue = int.tryParse(trimmed);
  return intValue != null ? Color(intValue) : fallback;
}
