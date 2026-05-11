import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/providers.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../database/db_helper.dart';
import '../utils/nutrition_calc.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final nutAsync     = ref.watch(nutritionProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('个人资料'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) {
              ref.invalidate(profileProvider);
              ref.invalidate(nutritionProvider);
            }),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('暂无资料'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Avatar + name
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF9C94FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text('G',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(profile.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      NutritionCalculator.goalLabels[profile.goal] ??
                          profile.goal,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),

              // Body stats
              const SectionHeader(title: '身体数据'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: StatTile(value: '${profile.height.round()}', label: '身高 cm')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(value: '${profile.weight}', label: '体重 kg')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(value: '${profile.age}', label: '年龄')),
                  ],
                ),
              ),

              // Nutrition summary
              nutAsync.when(
                data: (nut) {
                  if (nut == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: '营养概览'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: StatTile(
                                value: '${nut.calories.round()}',
                                label: '目标热量 kcal',
                                valueColor: AppTheme.amber)),
                            const SizedBox(width: 10),
                            Expanded(child: StatTile(
                                value: '${nut.protein.round()}g',
                                label: '蛋白质',
                                valueColor: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Activity level
              const SectionHeader(title: '活动水平'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_run_rounded,
                          color: AppTheme.teal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          NutritionCalculator
                                  .activityLabels[profile.activityLevel] ??
                              '未设置',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Weight log
              const SectionHeader(title: '体重记录'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeightLogWidget(),
              ),

              // Data export
              const SectionHeader(title: '数据备份'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () => _export(context),
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('导出全部数据 (JSON)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border, width: 0.5),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingScreen(),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final data = await DbHelper.instance.exportAll();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/gymlog_export.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'GymLog 数据备份');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Weight log widget
// ─────────────────────────────────────────────────────────────
class _WeightLogWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WeightLogWidget> createState() => _WeightLogWidgetState();
}

class _WeightLogWidgetState extends ConsumerState<_WeightLogWidget> {
  final _ctrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _logFuture;

  @override
  void initState() {
    super.initState();
    _logFuture = DbHelper.instance.getWeightLog();
  }

  void _reload() {
    setState(() {
      _logFuture = DbHelper.instance.getWeightLog();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '今日体重 (kg)',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final w = double.tryParse(_ctrl.text);
                  if (w == null) return;
                  await DbHelper.instance.logWeight(w);
                  _ctrl.clear();
                  _reload();
                  ref.invalidate(profileProvider);
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14)),
                child: const Text('记录'),
              ),
            ],
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _logFuture,
            builder: (context, snap) {
              final entries = snap.data ?? [];
              if (entries.isEmpty) return const SizedBox.shrink();

              final recent = entries.reversed.take(5).toList();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  const AppDivider(),
                  ...recent.map((e) {
                    final date =
                        DateTime.parse(e['date'] as String);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${(e['weight'] as num).toStringAsFixed(1)} kg',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Edit profile screen
// ─────────────────────────────────────────────────────────────
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl   = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String _gender   = 'male';
  String _goal     = 'recomp';
  double _activity = 1.375;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await DbHelper.instance.getProfile();
    if (p != null && mounted) {
      setState(() {
        _nameCtrl.text   = p.name;
        _heightCtrl.text = p.height.toString();
        _weightCtrl.text = p.weight.toString();
        _ageCtrl.text    = p.age.toString();
        _gender   = p.gender;
        _goal     = p.goal;
        _activity = p.activityLevel;
        _loaded   = true;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const LoadingScreen();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('编辑资料')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '昵称')),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '身高 (cm)')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '体重 (kg)')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '年龄')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _gender,
            dropdownColor: AppTheme.surface,
            decoration: const InputDecoration(labelText: '性别'),
            items: const [
              DropdownMenuItem(value: 'male',   child: Text('男')),
              DropdownMenuItem(value: 'female', child: Text('女')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _goal,
            dropdownColor: AppTheme.surface,
            decoration: const InputDecoration(labelText: '训练目标'),
            items: NutritionCalculator.goalLabels.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _goal = v!),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<double>(
            value: _activity,
            dropdownColor: AppTheme.surface,
            decoration: const InputDecoration(labelText: '活动水平'),
            items: NutritionCalculator.activityLabels.entries
                .map((e) => DropdownMenuItem(
                    value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final existing = await DbHelper.instance.getProfile();
    final updated = UserProfile(
      id: existing?.id,
      name: _nameCtrl.text.trim().isEmpty ? '训练者' : _nameCtrl.text.trim(),
      height: double.tryParse(_heightCtrl.text) ?? 177,
      weight: double.tryParse(_weightCtrl.text) ?? 66.5,
      age: int.tryParse(_ageCtrl.text) ?? 23,
      gender: _gender,
      goal: _goal,
      activityLevel: _activity,
    );
    await DbHelper.instance.saveProfile(updated);
    if (mounted) Navigator.pop(context);
  }
}
