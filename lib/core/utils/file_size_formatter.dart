abstract final class FileSizeFormatter {
  /// Formats a byte count into a human-readable string.
  ///
  /// Examples: "456 B", "1.2 KB", "3.5 MB", "1.0 GB"
  static String format(int bytes) {
    if (bytes < 0) return '0 B';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) return '$bytes B';

    // Remove trailing zero after decimal when not needed.
    final formatted = value.toStringAsFixed(1);
    return '$formatted ${units[unitIndex]}';
  }
}
