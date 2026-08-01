import 'package:flutter/material.dart';

class CefrLevelBadge extends StatelessWidget {
  final String level; // A1, A2, B1, B2, C1, C2

  const CefrLevelBadge({
    super.key,
    required this.level,
  });

  Color _getBadgeColor(String lvl) {
    switch (lvl.toUpperCase()) {
      case 'A1':
      case 'A2':
        return const Color(0xFF22C55E); // Green
      case 'B1':
      case 'B2':
        return const Color(0xFF5B5BF6); // Indigo brandPrimary
      case 'C1':
      case 'C2':
        return const Color(0xFFFF6B3D); // Coral
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
