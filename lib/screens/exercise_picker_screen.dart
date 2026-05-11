import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../database/db_helper.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState
    extends ConsumerState<ExercisePickerScreen> {
  String _query = '';
  String? _filterGroup;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final groups = muscleLabels.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('选择动作'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddCustom(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('自定义'),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary, size: 20),
                hintText: '搜索动作...',
              ),
            ),
          ),

          // Muscle filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: groups.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return FilterChip(
                    label: const Text('全部'),
                    selected: _filterGroup == null,
                    onSelected: (_) =>
                        setState(() => _filterGroup = null),
                  );
                }
                final g = groups[i - 1];
                return FilterChip(
                  label: Text(muscleLabels[g] ?? g),
                  selected: _filterGroup == g,
                  onSelected: (_) =>
                      setState(() => _filterGroup = g),
                );
              },
            ),
          ),

          const AppDivider(),

          // Results
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises.where((e) {
                  final matchGroup = _filterGroup == null ||
                      e.muscleGroup == _filterGroup;
                  final matchQuery = _query.isEmpty ||
                      e.name.toLowerCase().contains(_query.toLowerCase());
                  return matchGroup && matchQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: '没有找到动作',
                    subtitle: '可以点击右上角自定义添加',
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const AppDivider(),
                  itemBuilder: (_, i) {
                    final ex = filtered[i];
                    return ListTile(
                      onTap: () => Navigator.pop(context, ex),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      title: Text(ex.name,
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: MuscleChip(muscleGroup: ex.muscleGroup),
                      trailing: ex.isCustom
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppTheme.amber, size: 14),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppTheme.textHint, size: 18),
                                  onPressed: () =>
                                      _deleteCustom(context, ref, ex),
                                ),
                              ],
                            )
                          : const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textHint, size: 18),
                    );
                  },
                );
              },
              loading: () => const LoadingScreen(),
              error: (e, _) => ErrorWidget2(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustom(BuildContext context) async {
    final nameCtrl  = TextEditingController();
    String group = 'chest';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('自定义动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: '动作名称', hintText: '例如: 斜板哑铃弯举'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: group,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(labelText: '肌肉群'),
                items: muscleLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setDlg(() => group = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                await DbHelper.instance
                    .addCustomExercise(name, group);
                ref.invalidate(exercisesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCustom(
      BuildContext context, WidgetRef ref, ExerciseDefinition ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('删除自定义动作'),
        content: Text('确定要删除 "${ex.name}" 吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper.instance.deleteExercise(ex.id!);
      ref.invalidate(exercisesProvider);
    }
  }
}
