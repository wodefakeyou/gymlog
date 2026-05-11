import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'active_session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final cycleAsync   = ref.watch(activeCycleProvider);
    final statsAsync   = ref.watch(statsProvider);
    final sessionState = ref.watch(sessionProvider);
    final nutAsync     = ref.watch(nutritionProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium),
                        const SizedBox(height: 2),
                        profileAsync.when(
                          data: (p) => Text(
                            p?.name ?? '训练者',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge,
                          ),
                          loading: () => const Text(''),
                          error: (_, __) => const Text('训练者'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF9C94FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('G',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Active session banner ────────────────────────────
            if (sessionState.isActive) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ActiveSessionScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.5),
                          width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('训练进行中 — 点击继续',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppTheme.primary)),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── Cycle info ──────────────────────────────────────
            const SectionHeader(title: '当前周期'),
            cycleAsync.when(
              data: (cycle) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardDecoration(highlight: true),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cycle != null
                                  ? '第 ${cycle['number']} 轮训练'
                                  : '暂无训练周期',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                            if (cycle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '开始于 ${DateFormat('M月d日').format(DateTime.parse(cycle['start_date'] as String))}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.loop_rounded,
                          color: AppTheme.primary, size: 28),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Quick stats ─────────────────────────────────────
            const SectionHeader(title: '累计数据'),
            statsAsync.when(
              data: (stats) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '${stats['sessions']}',
                        label: '总训练次数',
                        valueColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: '${stats['cycles']}',
                        label: '完成轮次',
                        valueColor: AppTheme.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        value: _fmtVol(stats['totalVolume'] as double),
                        label: '总训练量',
                        valueColor: AppTheme.green,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Nutrition summary ───────────────────────────────
            const SectionHeader(title: '今日营养目标'),
            nutAsync.when(
              data: (nut) {
                if (nut == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('总热量',
                                style: Theme.of(context).textTheme.bodyMedium),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: '${nut.calories.round()}',
                                  style: const TextStyle(
                                      color: AppTheme.amber,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(
                                  text: ' kcal',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                ),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MacroChip('蛋白质',
                                '${nut.protein.round()}g', AppTheme.primary),
                            const SizedBox(width: 8),
                            _MacroChip('碳水',
                                '${nut.carbs.round()}g', AppTheme.green),
                            const SizedBox(width: 8),
                            _MacroChip('脂肪',
                                '${nut.fat.round()}g', AppTheme.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Start button ────────────────────────────────────
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!sessionState.isActive) {
                    await ref.read(sessionProvider.notifier).start();
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActiveSessionScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                    sessionState.isActive ? '继续今日训练' : '开始今日训练'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6)  return '夜深了 🌙';
    if (h < 12) return '早上好 ☀️';
    if (h < 18) return '下午好 💪';
    return '晚上好 🌙';
  }

  String _fmtVol(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}t';
    return '${v.round()}kg';
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
