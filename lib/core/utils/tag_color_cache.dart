import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Singleton cache that loads tag colors from the server.
/// Falls back to a deterministic hash when server color is unavailable.
class TagColorCache {
  TagColorCache._();

  static final instance = TagColorCache._();

  final Map<String, String> _colors = {}; // name → hex
  bool _loaded = false;

  static const presetColors = <({String hex, String name})>[
    // Row 1 — vivid
    (hex: '#EF4444', name: 'Red'),
    (hex: '#F97316', name: 'Orange'),
    (hex: '#F59E0B', name: 'Amber'),
    (hex: '#EAB308', name: 'Yellow'),
    (hex: '#22C55E', name: 'Green'),
    (hex: '#14B8A6', name: 'Teal'),
    (hex: '#06B6D4', name: 'Cyan'),
    (hex: '#3B82F6', name: 'Blue'),
    // Row 2 — rich
    (hex: '#6366F1', name: 'Indigo'),
    (hex: '#8B5CF6', name: 'Violet'),
    (hex: '#A855F7', name: 'Purple'),
    (hex: '#D946EF', name: 'Fuchsia'),
    (hex: '#EC4899', name: 'Pink'),
    (hex: '#F43F5E', name: 'Rose'),
    (hex: '#10B981', name: 'Emerald'),
    (hex: '#0EA5E9', name: 'Sky'),
    // Row 3 — muted / neutral
    (hex: '#64748B', name: 'Slate'),
    (hex: '#78716C', name: 'Stone'),
    (hex: '#6B7280', name: 'Gray'),
    (hex: '#84CC16', name: 'Lime'),
    (hex: '#059669', name: 'Sea Green'),
    (hex: '#0891B2', name: 'Dark Cyan'),
    (hex: '#7C3AED', name: 'Dark Violet'),
    (hex: '#BE185D', name: 'Dark Pink'),
  ];

  Future<void> load() async {
    if (_loaded) return;
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/tags');
      final list = response.data?['data'] as List<dynamic>? ?? [];
      for (final tag in list) {
        if (tag is Map<String, dynamic>) {
          final name = tag['name'] as String? ?? '';
          final color = tag['color'] as String?;
          if (name.isNotEmpty && color != null && color.isNotEmpty) {
            _colors[name.toLowerCase()] = color;
          }
        }
      }
      _loaded = true;
    } catch (_) {
      // Silently fail — will use hash fallback
    }
  }

  /// Get the color for a tag name. Prefers server color, falls back to hash.
  Color colorFor(String tagName) {
    final hex = _colors[tagName.toLowerCase()];
    if (hex != null) return _parseHex(hex);
    return _hashColor(tagName);
  }

  /// Get hex string for a tag name.
  String hexFor(String tagName) {
    return _colors[tagName.toLowerCase()] ?? _hashHex(tagName);
  }

  /// Update cache when a tag is created/edited.
  void put(String name, String hex) {
    _colors[name.toLowerCase()] = hex;
  }

  void invalidate() {
    _colors.clear();
    _loaded = false;
  }

  static Color _parseHex(String hex) {
    if (hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
    return Colors.grey;
  }

  static Color _hashColor(String name) {
    return _parseHex(_hashHex(name));
  }

  static String _hashHex(String name) {
    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return presetColors[hash.abs() % presetColors.length].hex;
  }
}
