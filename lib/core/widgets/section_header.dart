import 'package:flutter/material.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';

/// כותרת מקטע עם אייקון צבעוני — לקריאות וחידוד ויזואלי.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accent = ContentAccent.workout,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final ContentAccent accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final color = brand.contentAccent(accent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brand.contentSurface(accent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon ?? _defaultIcon(accent), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.silverDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _defaultIcon(ContentAccent a) => switch (a) {
        ContentAccent.workout => Icons.fitness_center,
        ContentAccent.exercise => Icons.sports_gymnastics,
        ContentAccent.plan => Icons.list_alt,
        ContentAccent.calendar => Icons.calendar_month,
      };
}
