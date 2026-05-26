import 'package:flutter/material.dart';

/// טאבים ראשיים ב-Bottom Navigation.
enum AppTab {
  home(
    label: 'בית',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  calendar(
    label: 'לוח',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  exercises(
    label: 'תרגילים',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center,
  ),
  plans(
    label: 'תוכניות',
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
  );

  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
