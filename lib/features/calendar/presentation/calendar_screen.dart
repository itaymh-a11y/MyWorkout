import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/features/calendar/application/calendar_providers.dart';
import 'package:myworkout/features/tracking/presentation/widgets/day_journal.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  String _weekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    const months = [
      'ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יונ׳',
      'יול׳', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳',
    ];
    if (weekStart.month == end.month) {
      return '${weekStart.day}–${end.day} ${months[weekStart.month - 1]} ${weekStart.year}';
    }
    return '${weekStart.day} ${months[weekStart.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(calendarWeekStartProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final byDay = ref.watch(sessionsByDayInWeekProvider);
    final daySessions = ref.watch(sessionsOnSelectedDayProvider);
    final markers = ref.watch(calendarDayMarkersProvider);
    final weekSessionsAsync = ref.watch(sessionsInWeekProvider);
    final theme = Theme.of(context);
    final brand = context.brand;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'שבוע קודם',
                onPressed: () {
                  ref.read(calendarWeekStartProvider.notifier).state =
                      weekStart.subtract(const Duration(days: 7));
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _weekLabel(weekStart),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'שבוע הבא',
                onPressed: () {
                  ref.read(calendarWeekStartProvider.notifier).state =
                      weekStart.add(const Duration(days: 7));
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: weekSessionsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('שגיאה בטעינה: $e'),
            data: (_) => Row(
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final key = dayKey(day);
                final count = byDay[key]?.length ?? 0;
                final hasExtra = markers[key]?.hasExtra ?? false;
                final isSelected = dayKey(selectedDay) == key;
                final isToday = dayKey(DateTime.now()) == key;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: isSelected
                          ? brand.contentSurface(ContentAccent.calendar)
                          : isToday
                              ? AppColors.silverMuted
                              : AppColors.cardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? brand.calendar
                              : isToday
                                  ? AppColors.silver
                                  : AppColors.silverLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      elevation: isSelected ? 1 : 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ref.read(calendarSelectedDayProvider.notifier).state =
                              day;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              Text(
                                hebrewWeekdays[i],
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${day.day}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? brand.calendar
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (count > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brand.workout,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 18),
                              const SizedBox(height: 4),
                              if (hasExtra)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: brand.calendar,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DayJournal(
            day: selectedDay,
            sessions: daySessions,
          ),
        ),
      ],
    );
  }
}
