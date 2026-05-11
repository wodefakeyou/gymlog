// ============================================================
// UserProfile model
// ============================================================
class UserProfile {
  final int? id;
  final String name;
  final double height;      // cm
  final double weight;      // kg
  final int age;
  final String gender;      // 'male' | 'female'
  final String goal;        // 'recomp' | 'bulk' | 'cut'
  final double activityLevel; // 1.2 | 1.375 | 1.55 | 1.725 | 1.9

  const UserProfile({
    this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.goal,
    required this.activityLevel,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'height': height,
    'weight': weight,
    'age': age,
    'gender': gender,
    'goal': goal,
    'activity_level': activityLevel,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] as int?,
    name: m['name'] as String,
    height: (m['height'] as num).toDouble(),
    weight: (m['weight'] as num).toDouble(),
    age: m['age'] as int,
    gender: m['gender'] as String,
    goal: m['goal'] as String,
    activityLevel: (m['activity_level'] as num).toDouble(),
  );

  UserProfile copyWith({
    int? id, String? name, double? height, double? weight,
    int? age, String? gender, String? goal, double? activityLevel,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    goal: goal ?? this.goal,
    activityLevel: activityLevel ?? this.activityLevel,
  );

  // Default user profile pre-filled with user's data
  static UserProfile get defaultProfile => const UserProfile(
    name: '训练者',
    height: 177,
    weight: 66.5,
    age: 23,
    gender: 'male',
    goal: 'recomp',
    activityLevel: 1.375,
  );
}

// ============================================================
// Cycle model — covers full-body round, not calendar week
// ============================================================
class Cycle {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final int number;

  const Cycle({
    this.id,
    required this.startDate,
    this.endDate,
    required this.number,
  });

  bool get isActive => endDate == null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'number': number,
  };

  factory Cycle.fromMap(Map<String, dynamic> m) => Cycle(
    id: m['id'] as int?,
    startDate: DateTime.parse(m['start_date'] as String),
    endDate: m['end_date'] != null ? DateTime.parse(m['end_date'] as String) : null,
    number: m['number'] as int,
  );
}

// ============================================================
// Weight log entry
// ============================================================
class WeightEntry {
  final int? id;
  final double weight;
  final DateTime date;

  const WeightEntry({this.id, required this.weight, required this.date});

  Map<String, dynamic> toMap() => {
    'id': id,
    'weight': weight,
    'date': date.toIso8601String(),
  };

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
    id: m['id'] as int?,
    weight: (m['weight'] as num).toDouble(),
    date: DateTime.parse(m['date'] as String),
  );
}
