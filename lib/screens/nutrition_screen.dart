import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../utils/nutrition_calc.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutAsync = ref.watch(nutritionProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('营养目标')),
      body: nutAsync.when(
        data: (nut) {
          if (nut == null) {
            return const Center(child: Text('请先完善个人资料'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Calorie ring
              _CalorieRing(nut: nut),

              // BMR / TDEE info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: StatTile(
                      value: '${nut.bmr.round()}',
                      label: '基础代谢 BMR (kcal)',
                      valueColor: AppTheme.teal,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(
                      value: '${nut.tdee.round()}',
                      label: '每日消耗 TDEE (kcal)',
                      valueColor: AppTheme.green,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              profileAsync.when(
                data: (p) {
                  if (p == null) return const SizedBox.shrink();
                  final desc = NutritionCalculator.goalDescriptions[p.goal] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: cardDecoration(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppTheme.primary, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(desc,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Macro bars
              const SectionHeader(title: '宏量营养素目标'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    MacroBar(
                      label: '蛋白质',
                      current: nut.protein,
                      target: nut.protein,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 10),
                    MacroBar(
                      label: '碳水化合物',
                      current: nut.carbs,
                      target: nut.carbs,
                      color: AppTheme.green,
                    ),
                    const SizedBox(height: 10),
                    MacroBar(
                      label: '脂肪',
                      current: nut.fat,
                      target: nut.fat,
                      color: AppTheme.amber,
                    ),
                  ],
                ),
              ),

              // Food guide
              const SectionHeader(title: '每日推荐食物'),
              ..._foodGuide(nut).map((item) => _FoodTile(item: item)),

              // Science footnote
              const SectionHeader(title: '计算依据'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Footnote('BMR', 'Mifflin-St Jeor 公式（2002年元分析验证）'),
                      SizedBox(height: 6),
                      _Footnote('蛋白质', '2.2 g/kg — Morton 2018 元分析上限，最大化增肌效果'),
                      SizedBox(height: 6),
                      _Footnote('脂肪', '≥ 0.85 g/kg — ISSN 立场声明，维持激素健康'),
                      SizedBox(height: 6),
                      _Footnote('热量策略', '增肌减脂同步 -150 kcal（Barakat 2020）'),
                    ],
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

  List<_FoodItem> _foodGuide(NutritionTarget nut) {
    // Based on actual macro targets for this user (177cm/66.5kg/23yo male/recomp)
    return [
      _FoodItem('🥚', '鸡蛋（全蛋）', '3个 · 早餐', '21g 蛋白质', AppTheme.amber),
      _FoodItem('🍗', '鸡胸肉', '${(nut.protein * 0.4).round()}g · 午餐',
          '${((nut.protein * 0.4) * 0.31).round()}g 蛋白质', AppTheme.primary),
      _FoodItem('🐟', '三文鱼 / 金枪鱼', '150g · 晚餐', '优质蛋白 + Omega-3', AppTheme.teal),
      _FoodItem('🥛', '低脂牛奶 / 蛋白粉', '训练后 30 分钟内',
          '${((nut.protein * 0.15)).round()}g 蛋白质', AppTheme.green),
      _FoodItem('🍚', '白米饭 / 糙米', '${(nut.carbs * 0.35).round()}g(熟重) · 午餐',
          '补充运动所需碳水', AppTheme.green),
      _FoodItem('🥑', '牛油果 / 橄榄油', '适量 · 全天', '提供优质不饱和脂肪', AppTheme.amber),
      _FoodItem('🥦', '西兰花 / 菠菜', '随意 · 全天', '维生素、矿物质、膳食纤维', AppTheme.teal),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// Calorie ring SVG
// ─────────────────────────────────────────────────────────────
class _CalorieRing extends StatelessWidget {
  final NutritionTarget nut;

  const _CalorieRing({required this.nut});

  @override
  Widget build(BuildContext context) {
    final cal = nut.calories.round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: cardDecoration(highlight: true),
        child: Column(
          children: [
            Text('每日目标热量',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            CustomPaint(
              size: const Size(160, 160),
              painter: _RingPainter(
                protein: nut.protein * 4,
                carbs: nut.carbs * 4,
                fat: nut.fat * 9,
              ),
              child: SizedBox(
                width: 160,
                height: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$cal',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700)),
                    const Text('kcal',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.primary, label: '蛋白质'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.green, label: '碳水'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.amber, label: '脂肪'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  _RingPainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    final total = protein + carbs + fat;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 16.0;

    final bg = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bg);

    final segments = [
      (protein / total, AppTheme.primary),
      (carbs / total, AppTheme.green),
      (fat / total, AppTheme.amber),
    ];

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.$1 * 2 * math.pi * 0.98;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + 0.015;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _FoodItem {
  final String emoji, name, amount, macro;
  final Color color;

  const _FoodItem(this.emoji, this.name, this.amount, this.macro, this.color);
}

class _FoodTile extends StatelessWidget {
  final _FoodItem item;

  const _FoodTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(item.amount,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.macro,
                  style: TextStyle(
                      color: item.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  final String title;
  final String desc;

  const _Footnote(this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '$title  ',
          style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        TextSpan(
          text: desc,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
        ),
      ]),
    );
  }
}
