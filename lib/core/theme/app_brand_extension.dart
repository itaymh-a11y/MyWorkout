import 'package:flutter/material.dart';
import 'package:myworkout/core/navigation/app_tab.dart';
import 'package:myworkout/core/theme/app_colors.dart';

/// סוג תוכן — לצבעי הדגשה עקביים בכרטיסים וכותרות.
enum ContentAccent {
  workout,
  exercise,
  plan,
  calendar,
}

/// צבעי מותג נוספים — טאבים, אימונים, תרגילים ותוכניות.
@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.tabHome,
    required this.tabCalendar,
    required this.tabExercises,
    required this.tabPlans,
    required this.workout,
    required this.exercise,
    required this.plan,
    required this.calendar,
    required this.star,
  });

  final Color tabHome;
  final Color tabCalendar;
  final Color tabExercises;
  final Color tabPlans;
  final Color workout;
  final Color exercise;
  final Color plan;
  final Color calendar;
  final Color star;

  static const light = AppBrandColors(
    tabHome: AppColors.ember,
    tabCalendar: AppColors.navyMid,
    tabExercises: AppColors.navy,
    tabPlans: AppColors.silverDark,
    workout: AppColors.ember,
    exercise: AppColors.navy,
    plan: AppColors.silverDark,
    calendar: AppColors.navyMid,
    star: AppColors.starGold,
  );

  Color tabAccent(AppTab tab) => switch (tab) {
        AppTab.home => tabHome,
        AppTab.calendar => tabCalendar,
        AppTab.exercises => tabExercises,
        AppTab.plans => tabPlans,
      };

  Color contentAccent(ContentAccent type) => switch (type) {
        ContentAccent.workout => workout,
        ContentAccent.exercise => exercise,
        ContentAccent.plan => plan,
        ContentAccent.calendar => calendar,
      };

  Color contentSurface(ContentAccent type) => switch (type) {
        ContentAccent.workout => AppColors.emberMuted,
        ContentAccent.exercise => const Color(0xFFE8EEF5),
        ContentAccent.plan => AppColors.silverMuted,
        ContentAccent.calendar => const Color(0xFFE6ECF4),
      };

  @override
  AppBrandColors copyWith({
    Color? tabHome,
    Color? tabCalendar,
    Color? tabExercises,
    Color? tabPlans,
    Color? workout,
    Color? exercise,
    Color? plan,
    Color? calendar,
    Color? star,
  }) {
    return AppBrandColors(
      tabHome: tabHome ?? this.tabHome,
      tabCalendar: tabCalendar ?? this.tabCalendar,
      tabExercises: tabExercises ?? this.tabExercises,
      tabPlans: tabPlans ?? this.tabPlans,
      workout: workout ?? this.workout,
      exercise: exercise ?? this.exercise,
      plan: plan ?? this.plan,
      calendar: calendar ?? this.calendar,
      star: star ?? this.star,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      tabHome: Color.lerp(tabHome, other.tabHome, t)!,
      tabCalendar: Color.lerp(tabCalendar, other.tabCalendar, t)!,
      tabExercises: Color.lerp(tabExercises, other.tabExercises, t)!,
      tabPlans: Color.lerp(tabPlans, other.tabPlans, t)!,
      workout: Color.lerp(workout, other.workout, t)!,
      exercise: Color.lerp(exercise, other.exercise, t)!,
      plan: Color.lerp(plan, other.plan, t)!,
      calendar: Color.lerp(calendar, other.calendar, t)!,
      star: Color.lerp(star, other.star, t)!,
    );
  }
}

extension AppBrandContext on BuildContext {
  AppBrandColors get brand =>
      Theme.of(this).extension<AppBrandColors>() ?? AppBrandColors.light;
}
