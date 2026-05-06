import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum BadgeType { green, amber, red, blue, grey }

class GymBadge extends StatelessWidget {
  final String text;
  final BadgeType type;
  final double fontSize;

  const GymBadge({
    super.key,
    required this.text,
    this.type = BadgeType.amber,
    this.fontSize = 11,
  });

  Color get _fg {
    switch (type) {
      case BadgeType.green: return AppTheme.success;
      case BadgeType.amber: return AppTheme.primary;
      case BadgeType.red:   return AppTheme.error;
      case BadgeType.blue:  return AppTheme.info;
      case BadgeType.grey:  return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _fg.withValues(alpha: 0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: _fg.withValues(alpha: 0.18),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        color: _fg,
        fontSize: fontSize < 11 ? 11 : fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  );

  /// Factory helpers
  static GymBadge active()    => const GymBadge(text: 'Actif',      type: BadgeType.green);
  static GymBadge inactive()  => const GymBadge(text: 'Inactif',    type: BadgeType.grey);
  static GymBadge expired()   => const GymBadge(text: 'Expiré',     type: BadgeType.red);
  static GymBadge available() => const GymBadge(text: 'Disponible', type: BadgeType.green);
  static GymBadge busy()      => const GymBadge(text: 'Occupé',     type: BadgeType.amber);
}
