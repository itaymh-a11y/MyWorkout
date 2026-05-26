import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/navigation/app_tab.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/widgets/active_workout_banner.dart';
import 'package:myworkout/core/widgets/app_logo.dart';
import 'package:myworkout/features/auth/application/auth_providers.dart';
import 'package:myworkout/features/calendar/application/calendar_providers.dart';
import 'package:myworkout/features/calendar/presentation/calendar_screen.dart';
import 'package:myworkout/features/calendar/presentation/manual_session_screen.dart';
import 'package:myworkout/features/exercises/presentation/category_manage_screen.dart';
import 'package:myworkout/features/exercises/presentation/exercise_form_screen.dart';
import 'package:myworkout/features/exercises/presentation/exercises_screen.dart';
import 'package:myworkout/features/home/presentation/home_screen.dart';
import 'package:myworkout/features/plans/presentation/plan_form_screen.dart';
import 'package:myworkout/features/plans/presentation/plans_screen.dart';

/// מעטפת ראשית: AppBar + תוכן טאב + Bottom Navigation (4 טאבים).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  AppTab _currentTab = AppTab.home;

  static const List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    ExercisesScreen(),
    PlansScreen(),
  ];

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final tabColor = brand.tabAccent(_currentTab);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 8),
          child: Center(child: AppLogo.small()),
        ),
        leadingWidth: 56,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentTab.selectedIcon, color: tabColor, size: 22),
            const SizedBox(width: 8),
            Text(_currentTab.label),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: tabColor.withValues(alpha: 0.85),
          ),
        ),
        actions: [
          if (_currentTab == AppTab.exercises)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoryManageScreen(),
                  ),
                );
              },
              tooltip: 'ניהול קטגוריות',
              icon: Icon(Icons.category_outlined, color: brand.tabExercises),
            ),
          IconButton(
            onPressed: _signOut,
            tooltip: 'התנתק',
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          const ActiveWorkoutBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentTab.index,
              children: _screens,
            ),
          ),
        ],
      ),
      floatingActionButton: switch (_currentTab) {
        AppTab.exercises => FloatingActionButton(
            heroTag: 'fab_exercises',
            backgroundColor: brand.tabExercises,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExerciseFormScreen(),
                ),
              );
            },
            tooltip: 'תרגיל חדש',
            child: const Icon(Icons.add),
          ),
        AppTab.plans => FloatingActionButton(
            heroTag: 'fab_plans',
            backgroundColor: brand.tabPlans,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlanFormScreen(),
                ),
              );
            },
            tooltip: 'תוכנית חדשה',
            child: const Icon(Icons.add),
          ),
        AppTab.calendar => FloatingActionButton(
            heroTag: 'fab_calendar',
            backgroundColor: brand.tabCalendar,
            onPressed: () {
              final day = ref.read(calendarSelectedDayProvider);
              ManualSessionScreen.open(context, initialDate: day);
            },
            tooltip: 'הוסף אימון ידני',
            child: const Icon(Icons.history_edu),
          ),
        _ => null,
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab.index,
        indicatorColor: tabColor.withValues(alpha: 0.2),
        onDestinationSelected: (index) {
          setState(() => _currentTab = AppTab.values[index]);
        },
        destinations: [
          for (final tab in AppTab.values)
            NavigationDestination(
              icon: Icon(
                tab.icon,
                color: AppColors.silverDark,
              ),
              selectedIcon: Icon(
                tab.selectedIcon,
                color: brand.tabAccent(tab),
              ),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
