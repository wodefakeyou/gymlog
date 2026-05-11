import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../database/db_helper.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('数据分析')),
      body: statsAsync.when(
        data: (stats) {
          final prs = stats['prs'] as List<Map<String, dynamic>>;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Summary row
              const SectionHeader(title: '整体概览'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: StatTile(
                      value: '${stats['sessions']}',
                      label: '总训练次数',
                      valueColor: AppTheme.primary,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(
                      value: '${stats['cycles']}',
                      label: '完成轮次',
                      valueColor: AppTheme.teal,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(
                      value: _fmtVol(stats['totalVolume'] as double),
                      label: '累计训练量',
                      valueColor: AppTheme.green,
                    )),
                  ],
                ),
              ),

              // PRs
              const SectionHeader(title: '个人记录 PR'),
              if (prs.isEmpty)
                const EmptyState(
                  icon: Icons.emoji_events_rounded,
                  title: '暂无 PR 记录',
                  subtitle: '完成训练后会自动记录',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: cardDecoration(),
                    child: Column(
                      children: prs.asMap().entries.map((entry) {
                        final pr = entry.value;
                        final isLast = entry.key == prs.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  MuscleChip(
                                      muscleGroup:
                                          pr['muscle_group'] as String),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(pr['name'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${(pr['max_w'] as num).toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                            color: AppTheme.amber,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                      const Text('最大重量',
                                          style: TextStyle(
                                              color:
                                                  AppTheme.textSecondary,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) const AppDivider(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Progress chart section
              const SectionHeader(title: '动作进步趋势'),
              _ExerciseProgressPicker(),
            ],
          );
        },
        loading: () => const LoadingScreen(),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }

  String _fmtVol(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}t';
    return '${v.round()}kg';
  }
}

// ─────────────────────────────────────────────────────────────
// Pick an exercise → show its weight progress chart
// ─────────────────────────────────────────────────────────────
class _ExerciseProgressPicker extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExerciseProgressPicker> createState() =>
      _ExerciseProgressPickerState();
}

class _ExerciseProgressPickerState
    extends ConsumerState<_ExerciseProgressPicker> {
  int? _selectedExId;
  String _selectedExName = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      data: (exercises) {
        return Column(
          children: [
            // Exercise dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonFormField<int>(
                value: _selectedExId,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(hintText: '选择动作查看进步曲线'),
                items: exercises
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedExId = v;
                    _selectedExName = exercises
                        .firstWhere((e) => e.id == v)
                        .name;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedExId != null)
              _ProgressChart(
                  exerciseId: _selectedExId!, exerciseName: _selectedExName),
          ],
        );
      },
      loading: () => const LoadingScreen(),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }
}

class _ProgressChart extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const _ProgressChart(
      {required this.exerciseId, required this.exerciseName});

  @override
  State<_ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<_ProgressChart> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DbHelper.instance.getExerciseProgress(widget.exerciseId);
  }

  @override
  void didUpdateWidget(_ProgressChart old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) {
      setState(() {
        _future =
            DbHelper.instance.getExerciseProgress(widget.exerciseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 200, child: LoadingScreen());
          }
          final data = snap.data ?? [];
          if (data.length < 2) {
            return Container(
              height: 160,
              decoration: cardDecoration(),
              child: const EmptyState(
                icon: Icons.show_chart_rounded,
                title: '数据不足',
                subtitle: '至少需要 2 次训练记录才能显示趋势',
              ),
            );
          }

          final spots = data.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['max_w'] as num).toDouble(),
            );
          }).toList();

          final minY =
              (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5)
                  .clamp(0, double.infinity)
                  .toDouble();
          final maxY =
              spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                const Text('最大重量趋势 (kg)',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.border,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text('${v.round()}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Text('第${i + 1}次',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 9));
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primary.withOpacity(0.08),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.primary,
                              strokeWidth: 2,
                              strokeColor: AppTheme.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
