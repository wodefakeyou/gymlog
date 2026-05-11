import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/rest_timer.dart';
import 'exercise_picker_screen.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('训练中'),
            Text(_elapsed(session.startTime),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmEnd(context, ref),
            child: const Text('完成',
                style: TextStyle(
                    color: AppTheme.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: session.exercises.isEmpty
          ? _emptyState(context, ref)
          : _exerciseList(context, ref, session),
      bottomNavigationBar: _bottomBar(context, ref),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fitness_center_rounded,
              color: AppTheme.textHint, size: 48),
          const SizedBox(height: 16),
          Text('从添加动作开始',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickExercise(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加动作'),
          ),
        ],
      ),
    );
  }

  Widget _exerciseList(
      BuildContext context, WidgetRef ref, ActiveSession session) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // Volume summary chip
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _SummaryChip(
                  '${session.exercises.length} 个动作',
                  Icons.list_rounded),
              const SizedBox(width: 8),
              _SummaryChip(
                  '${session.totalSets} 组',
                  Icons.repeat_rounded),
              const SizedBox(width: 8),
              _SummaryChip(
                  '${(session.totalVolume / 1000).toStringAsFixed(1)} t',
                  Icons.monitor_weight_rounded),
            ],
          ),
        ),
        const SizedBox(height: 8),

        ...session.exercises.map((ex) => _ExerciseCard(exercise: ex)),

        // Rest timer
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: const RestTimer(),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickExercise(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加动作'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmEnd(context, ref),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('结束训练'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
    final def = await Navigator.push<ExerciseDefinition>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (def == null) return;
    await ref.read(sessionProvider.notifier).addExercise(def);
  }

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (session.exercises.isEmpty) {
      ref.read(sessionProvider.notifier).discard();
      if (context.mounted) Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('结束训练'),
        content: Text(
          '完成了 ${session.exercises.length} 个动作，共 ${session.totalSets} 组。',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('继续训练')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(sessionProvider.notifier).end();
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(statsProvider);
      ref.invalidate(activeCycleProvider);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _elapsed(DateTime? start) {
    if (start == null) return '';
    final d = DateTime.now().difference(start);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h 时 $m 分';
    return '$m 分钟';
  }
}

// ─────────────────────────────────────────────────────────────
// Per-exercise card
// ─────────────────────────────────────────────────────────────
class _ExerciseCard extends ConsumerWidget {
  final SessionExercise exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: cardDecoration(),
        child: Column(
          children: [
            // Exercise header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.exerciseName,
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        MuscleChip(muscleGroup: exercise.muscleGroup),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary, size: 18),
                    onPressed: () => ref
                        .read(sessionProvider.notifier)
                        .removeExercise(exercise.id!),
                  ),
                ],
              ),
            ),

            const AppDivider(),

            // Sets table header
            if (exercise.sets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(
                  children: const [
                    SizedBox(width: 28),
                    _TableHeader('重量(kg)', flex: 3),
                    _TableHeader('次数', flex: 2),
                    _TableHeader('RPE', flex: 2),
                    SizedBox(width: 32),
                  ],
                ),
              ),
              const AppDivider(),
              ...exercise.sets.asMap().entries.map((entry) =>
                  _SetRow(
                    index: entry.key,
                    set: entry.value,
                    seId: exercise.id!,
                  )),
              const AppDivider(),
            ],

            // Add set row
            _AddSetRow(exercise: exercise),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _TableHeader(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Set row (completed)
// ─────────────────────────────────────────────────────────────
class _SetRow extends ConsumerWidget {
  final int index;
  final SetEntry set;
  final int seId;

  const _SetRow({required this.index, required this.set, required this.seId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(set.weight.toString(),
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text('${set.reps}',
                style: const TextStyle(color: AppTheme.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text(
                set.rpe != null ? set.rpe!.toStringAsFixed(1) : '—',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(sessionProvider.notifier).deleteSet(seId, set.id!),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add set input row
// ─────────────────────────────────────────────────────────────
class _AddSetRow extends ConsumerStatefulWidget {
  final SessionExercise exercise;

  const _AddSetRow({required this.exercise});

  @override
  ConsumerState<_AddSetRow> createState() => _AddSetRowState();
}

class _AddSetRowState extends ConsumerState<_AddSetRow> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl   = TextEditingController();
  final _rpeCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fill from last session
    final hints = ref
        .read(sessionProvider.notifier)
        .getLastSetsHint(widget.exercise.id!);

    final setIdx = widget.exercise.sets.length;
    if (setIdx < hints.length) {
      _weightCtrl.text = hints[setIdx].weight.toString();
      _repsCtrl.text   = hints[setIdx].reps.toString();
    } else if (hints.isNotEmpty) {
      _weightCtrl.text = hints.last.weight.toString();
      _repsCtrl.text   = hints.last.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _rpeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final w = double.tryParse(_weightCtrl.text);
    final r = int.tryParse(_repsCtrl.text);
    if (w == null || r == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入重量和次数')),
      );
      return;
    }

    final rpe = double.tryParse(_rpeCtrl.text);
    final isNewPR = await ref.read(sessionProvider.notifier).addSet(
      seId: widget.exercise.id!,
      weight: w,
      reps: r,
      rpe: rpe,
    );

    if (isNewPR) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🏆  新个人记录！'),
                const Spacer(),
                Text('${w}kg',
                    style: const TextStyle(
                        color: AppTheme.amber,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }
    }

    _weightCtrl.clear();
    _repsCtrl.clear();
    _rpeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'kg',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '次',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _rpeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'RPE',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Session summary chip
// ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SummaryChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
