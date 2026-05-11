class ExerciseDefinition {
  final int? id;
  final String name;
  final String muscleGroup;
  final bool isCustom;

  const ExerciseDefinition({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'muscle_group': muscleGroup,
    'is_custom': isCustom ? 1 : 0,
  };

  factory ExerciseDefinition.fromMap(Map<String, dynamic> m) => ExerciseDefinition(
    id: m['id'] as int?,
    name: m['name'] as String,
    muscleGroup: m['muscle_group'] as String,
    isCustom: (m['is_custom'] as int) == 1,
  );
}

// ─────────────────────────────────────────────
// Built-in exercise library — can be expanded
// ─────────────────────────────────────────────
const List<Map<String, String>> kDefaultExercises = [
  // Chest
  {'name': '卧推',        'muscleGroup': 'chest'},
  {'name': '上斜卧推',    'muscleGroup': 'chest'},
  {'name': '下斜卧推',    'muscleGroup': 'chest'},
  {'name': '哑铃飞鸟',    'muscleGroup': 'chest'},
  {'name': '夹胸器械',    'muscleGroup': 'chest'},
  {'name': '俯卧撑',      'muscleGroup': 'chest'},
  {'name': '绳索夹胸',    'muscleGroup': 'chest'},

  // Back
  {'name': '引体向上',    'muscleGroup': 'back'},
  {'name': '高位下拉',    'muscleGroup': 'back'},
  {'name': '杠铃划船',    'muscleGroup': 'back'},
  {'name': '坐姿划船',    'muscleGroup': 'back'},
  {'name': '单臂哑铃划船','muscleGroup': 'back'},
  {'name': '硬拉',        'muscleGroup': 'back'},
  {'name': 'T杠划船',     'muscleGroup': 'back'},

  // Legs
  {'name': '深蹲',        'muscleGroup': 'legs'},
  {'name': '腿举',        'muscleGroup': 'legs'},
  {'name': '腿弯举',      'muscleGroup': 'legs'},
  {'name': '腿伸展',      'muscleGroup': 'legs'},
  {'name': '小腿提踵',    'muscleGroup': 'legs'},
  {'name': '臀推',        'muscleGroup': 'legs'},
  {'name': '保加利亚深蹲','muscleGroup': 'legs'},
  {'name': '罗马尼亚硬拉','muscleGroup': 'legs'},

  // Shoulders
  {'name': '站姿推举',    'muscleGroup': 'shoulders'},
  {'name': '哑铃侧平举',  'muscleGroup': 'shoulders'},
  {'name': '前平举',      'muscleGroup': 'shoulders'},
  {'name': '面拉',        'muscleGroup': 'shoulders'},
  {'name': '颈后推举',    'muscleGroup': 'shoulders'},
  {'name': 'Arnold推举',  'muscleGroup': 'shoulders'},

  // Biceps
  {'name': '哑铃弯举',    'muscleGroup': 'biceps'},
  {'name': '锤式弯举',    'muscleGroup': 'biceps'},
  {'name': '杠铃弯举',    'muscleGroup': 'biceps'},
  {'name': '集中弯举',    'muscleGroup': 'biceps'},
  {'name': '蜘蛛弯举',    'muscleGroup': 'biceps'},

  // Triceps
  {'name': '绳索下压',    'muscleGroup': 'triceps'},
  {'name': '过头臂屈伸',  'muscleGroup': 'triceps'},
  {'name': '窄距卧推',    'muscleGroup': 'triceps'},
  {'name': '双杠臂屈伸',  'muscleGroup': 'triceps'},
  {'name': '法式推举',    'muscleGroup': 'triceps'},

  // Core
  {'name': '卷腹',        'muscleGroup': 'core'},
  {'name': '平板支撑',    'muscleGroup': 'core'},
  {'name': '俄罗斯转体',  'muscleGroup': 'core'},
  {'name': '悬挂举腿',    'muscleGroup': 'core'},
  {'name': '仰卧起坐',    'muscleGroup': 'core'},
  {'name': '登山者',      'muscleGroup': 'core'},

  // Cardio
  {'name': '跑步机', 'muscleGroup': 'cardio'},
  {'name': '椭圆机', 'muscleGroup': 'cardio'},
  {'name': '跳绳',   'muscleGroup': 'cardio'},
  {'name': '划船机', 'muscleGroup': 'cardio'},
];
