import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myworkout/core/theme/app_brand_extension.dart';
import 'package:myworkout/core/theme/app_colors.dart';
import 'package:myworkout/core/utils/session_format.dart';
import 'package:myworkout/core/widgets/accent_card.dart';
import 'package:myworkout/features/calendar/application/calendar_providers.dart';
import 'package:myworkout/features/calendar/presentation/manual_session_screen.dart';
import 'package:myworkout/features/calendar/presentation/session_detail_screen.dart';
import 'package:myworkout/features/workout/application/session_delete.dart';
import 'package:myworkout/shared/models/workout_session.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'שבוע לפי א׳–ש׳',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'אימונים ב-${formatSessionDate(selectedDay)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: daySessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'אין אימונים ביום זה',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          ManualSessionScreen.open(
                            context,
                            initialDate: selectedDay,
                          );
                        },
                        icon: const Icon(Icons.history_edu),
                        label: const Text('הוסף אימון ידני'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: daySessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = daySessions[index];
                    return Dismissible(
                      key: ValueKey(session.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return confirmAndDeleteSession(
                          context,
                          ref,
                          sessionId: session.id,
                          planName: session.planName,
                        );
                      },
                      child: _SessionListTile(session: session),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SessionListTile extends StatelessWidget {
  const _SessionListTile({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final time = session.startedAt.toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return AccentCard(
      accent: ContentAccent.workout,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: brand.contentSurface(ContentAccent.workout),
          child: Icon(Icons.fitness_center, color: brand.workout, size: 22),
        ),
        title: Text(session.planName),
        subtitle: Text('$timeStr · ${formatDuration(session.durationSec)}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SessionDetailScreen(sessionId: session.id),
            ),
          );
        },
      ),
    );
  }
}
