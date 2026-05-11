import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../database/db_helper.dart';
import '../models/set_entry.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final allSessionsAsync = ref.watch(allSessionsProvider);
    final recentAsync      = ref.watch(recentSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('训练历史')),
      body: allSessionsAsync.when(
        data: (allSessions) {
          // Build set of dates that have sessions
          final trainDays = <DateTime>{};
          for (final s in allSessions) {
            final d = DateTime.parse(s['date'] as String);
            trainDays.add(DateTime(d.year, d.month, d.day));
          }

          return ListView(
            children: [
              // Calendar
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focused,
                selectedDayPredicate: (d) =>
                    _selected != null && isSameDay(_selected, d),
                onDaySelected: (sel, foc) =>
                    setState(() { _selected = sel; _focused = foc; }),
                onPageChanged: (foc) =>
                    setState(() => _focused = foc),
                calendarStyle: CalendarStyle(
                  defaultTextStyle:
                      const TextStyle(color: AppTheme.textPrimary),
                  weekendTextStyle:
                      const TextStyle(color: AppTheme.textSecondary),
                  outsideTextStyle:
                      const TextStyle(color: AppTheme.textHint),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: AppTheme.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  weekendStyle:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                eventLoader: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  return trainDays.contains(d) ? [d] : [];
                },
              ),

              const AppDivider(),

              // Selected day detail
              if (_selected != null) ...[
                _SelectedDayDetail(date: _selected!, allSessions: allSessions),
              ] else ...[
                const SectionHeader(title: '最近训练'),
                recentAsync.when(
                  data: (sessions) => sessions.isEmpty
                      ? const EmptyState(
                          icon: Icons.calendar_today_rounded,
                          title: '还没有训练记录',
                          subtitle: '完成第一次训练后会显示在这里',
                        )
                      : Column(
                          children: sessions
                              .map((s) => _SessionTile(session: s))
                              .toList(),
                        ),
                  loading: () => const LoadingScreen(),
                  error: (e, _) => ErrorWidget2(message: e.toString()),
                ),
              ],
            ],
          );
        },
        loading: () => const LoadingScreen(),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }
}

class _SelectedDayDetail extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> allSessions;

  const _SelectedDayDetail(
      {required this.date, required this.allSessions});

  @override
  Widget build(BuildContext context) {
    final daySessions = allSessions.where((s) {
      final d = DateTime.parse(s['date'] as String);
      return d.year == date.year &&
          d.month == date.month &&
          d.day == date.day;
    }).toList();

    if (daySessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '${DateFormat('M月d日').format(date)}  休息日',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
            title: DateFormat('M月d日').format(date)),
        ...daySessions.map((s) => _SessionTile(session: s)),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.parse(session['date'] as String);
    final endTime = session['end_time'] != null
        ? DateTime.parse(session['end_time'] as String)
        : null;
    final duration = endTime?.difference(date);

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SessionDetailScreen(sessionId: session['id'] as int)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.fitness_center_rounded,
            color: AppTheme.primary, size: 20),
      ),
      title: Text(
        DateFormat('M月d日 · HH:mm').format(date),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        duration != null
            ? '时长 ${_fmtDur(duration)}'
            : '未结束',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.textHint, size: 18),
    );
  }

  String _fmtDur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}时${d.inMinutes % 60}分';
    return '${d.inMinutes}分钟';
  }
}

// ─────────────────────────────────────────────────────────────
// Session detail drill-down
// ─────────────────────────────────────────────────────────────
class SessionDetailScreen extends StatefulWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late Future<List<_ExerciseWithSets>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ExerciseWithSets>> _load() async {
    final exRows =
        await DbHelper.instance.getSessionExercises(widget.sessionId);
    final result = <_ExerciseWithSets>[];
    for (final ex in exRows) {
      final sets =
          await DbHelper.instance.getSets(ex['id'] as int);
      result.add(_ExerciseWithSets(
        name: ex['exercise_name'] as String,
        muscleGroup: ex['muscle_group'] as String,
        sets: sets,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('训练详情')),
      body: FutureBuilder<List<_ExerciseWithSets>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingScreen();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fitness_center_rounded,
              title: '暂无记录',
              subtitle: '该训练没有动作数据',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: items.map((ex) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(ex.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                            ),
                            MuscleChip(muscleGroup: ex.muscleGroup),
                          ],
                        ),
                      ),
                      const AppDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: const [
                            SizedBox(width: 28),
                            Expanded(child: Text('重量(kg)',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10))),
                            Expanded(child: Text('次数',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10))),
                            Expanded(child: Text('训练量',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10))),
                          ],
                        ),
                      ),
                      const AppDivider(),
                      ...ex.sets.asMap().entries.map((entry) {
                        final s = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('${entry.key + 1}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ),
                              Expanded(
                                  child: Text('${s.weight}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                              Expanded(child: Text('${s.reps}')),
                              Expanded(
                                child: Text(
                                  '${s.volume.round()} kg',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(
                          '总训练量: ${ex.totalVolume.round()} kg',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ExerciseWithSets {
  final String name;
  final String muscleGroup;
  final List<SetEntry> sets;

  _ExerciseWithSets(
      {required this.name,
      required this.muscleGroup,
      required this.sets});

  double get totalVolume =>
      sets.fold(0.0, (s, e) => s + e.volume);
}
