import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.radius = 20,
    this.imageUrl,
    super.key,
  });

  final String name;
  final double radius;
  final String? imageUrl;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _backgroundColor {
    // Seed a consistent color from the name hash.
    const palette = <Color>[
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFFFB8C00),
      Color(0xFF00ACC1),
      Color(0xFF3949AB),
      Color(0xFF6D4C41),
      Color(0xFF546E7A),
      Color(0xFFD81B60),
    ];
    final hash = name.hashCode.abs();
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      backgroundImage: url != null ? NetworkImage(url) : null,
      onBackgroundImageError: url != null ? (_, __) {} : null,
      child: url == null
          ? Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
