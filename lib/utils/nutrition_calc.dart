import '../models/user_profile.dart';

// ============================================================
// NutritionTarget — calculated macro targets for the day
// ============================================================
class NutritionTarget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double bmr;
  final double tdee;

  const NutritionTarget({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.bmr,
    required this.tdee,
  });
}

// ============================================================
// NutritionCalculator
// Science reference:
//   BMR  → Mifflin-St Jeor (2002 meta-analysis validated)
//   TDEE → BMR × activity multiplier (Ainsworth 2011)
//   Protein → 1.6-2.2 g/kg (Morton 2018 meta-analysis)
//   Fat  → ≥ 0.7 g/kg (ISSN position stand)
//   Carbs → remaining calories
// ============================================================
class NutritionCalculator {
  NutritionCalculator._();

  /// Mifflin-St Jeor BMR (kcal/day)
  static double bmr(UserProfile p) {
    final base = 10 * p.weight + 6.25 * p.height - 5 * p.age;
    return p.gender == 'male' ? base + 5 : base - 161;
  }

  /// TDEE = BMR × Harris activity factor
  static double tdee(UserProfile p) => bmr(p) * p.activityLevel;

  /// Full calculation
  static NutritionTarget calculate(UserProfile p) {
    final bmrVal  = bmr(p);
    final tdeeVal = tdee(p);

    // ── Target calories by goal ──────────────────────────
    // Body recomp research (Barakat 2020): slight deficit
    // keeps body recomping for beginners & intermediates.
    // Bulk: +200-300 kcal (lean bulk), Cut: -300-400 kcal
    final double targetCal;
    switch (p.goal) {
      case 'bulk':  targetCal = (tdeeVal + 250).roundToDouble(); break;
      case 'cut':   targetCal = (tdeeVal - 350).roundToDouble(); break;
      case 'recomp':
      default:      targetCal = (tdeeVal - 150).roundToDouble(); break;
    }

    // ── Protein ─────────────────────────────────────────
    // 2.2 g/kg maximises MPS across literature (recomp needs high end)
    final protein = (p.weight * 2.2).roundToDouble();

    // ── Fat ─────────────────────────────────────────────
    // ≥ 0.8 g/kg for hormonal health; cut can go lower temporarily
    final double fatMultiplier;
    switch (p.goal) {
      case 'cut':   fatMultiplier = 0.8; break;
      case 'bulk':  fatMultiplier = 0.9; break;
      default:      fatMultiplier = 0.85; break;
    }
    final fat = (p.weight * fatMultiplier).roundToDouble();

    // ── Carbs fill remaining ─────────────────────────────
    double carbs = ((targetCal - protein * 4 - fat * 9) / 4).roundToDouble();
    if (carbs < 50) carbs = 50; // minimum floor

    return NutritionTarget(
      calories: targetCal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      bmr: bmrVal,
      tdee: tdeeVal,
    );
  }

  // ── Human-readable labels ────────────────────────────────
  static final Map<double, String> activityLabels = {
    1.2:   '久坐（几乎不运动）',
    1.375: '轻度活动（每周 1-3 次）',
    1.55:  '中度活动（每周 3-5 次）',
    1.725: '高度活动（每周 6-7 次）',
    1.9:   '极高活动（两练或体力劳动）',
  };

  static final Map<String, String> goalLabels = {
    'recomp': '增肌减脂同步',
    'bulk':   '增肌为主（热量盈余）',
    'cut':    '减脂为主（热量赤字）',
  };

  static final Map<String, String> goalDescriptions = {
    'recomp':
      '同步增肌减脂适合初级训练者与体脂中等的中级训练者。'
      '轻微热量赤字（-150 kcal）配合高蛋白饮食，让身体优先燃脂、同时保留肌肉。'
      '进度比单纯增肌或减脂慢，但体成分变化更均衡。',
    'bulk':
      '增肌期采用适度热量盈余（+250 kcal），最大化肌肉合成速率。'
      '适合体脂 < 15%（男）或 < 25%（女）时进行，避免过多脂肪增长。',
    'cut':
      '减脂期采用适度热量赤字（-350 kcal），保留最大肌肉量。'
      '高蛋白摄入是保肌的核心，同时配合抗阻训练刺激。',
  };
}
