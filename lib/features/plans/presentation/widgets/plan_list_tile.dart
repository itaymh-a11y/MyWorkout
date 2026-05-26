import 'package:flutter/material.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/shared/models/workout_plan.dart';

class PlanListTile extends StatelessWidget {
  const PlanListTile({
    super.key,
    required this.plan,
    required this.exerciseCount,
    required this.completedSessionCount,
    required this.onTap,
    required this.onStarToggle,
  });

  final WorkoutPlan plan;
  final int exerciseCount;
  final int completedSessionCount;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: plan.isStarred
            ? AppColors.emberMuted
            : AppColors.silverMuted,
        child: Icon(
          plan.isStarred ? Icons.star : Icons.list_alt,
          color: plan.isStarred ? brand.star : brand.plan,
        ),
      ),
      title: Text(plan.name),
      subtitle: Text(
        '$completedSessionCount אימונים בוצעו · $exerciseCount תרגילים · מנוחה ${plan.defaultRestSec} שנ׳',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        tooltip: plan.isStarred ? 'הסר כוכב' : 'סמן כוכב (עד 3)',
        icon: Icon(
          plan.isStarred ? Icons.star : Icons.star_border,
          color: plan.isStarred ? brand.star : AppColors.silver,
        ),
        onPressed: onStarToggle,
      ),
    );
  }
}
