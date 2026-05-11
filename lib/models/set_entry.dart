// ============================================================
// SetEntry — smallest recording unit
// ============================================================
class SetEntry {
  final int? id;
  final int sessionExerciseId;
  final double weight;   // kg
  final int reps;
  final double? rpe;     // 1-10, optional
  final bool isFailure;
  final DateTime timestamp;

  SetEntry({
    this.id,
    required this.sessionExerciseId,
    required this.weight,
    required this.reps,
    this.rpe,
    this.isFailure = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get volume => weight * reps;

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_exercise_id': sessionExerciseId,
    'weight': weight,
    'reps': reps,
    'rpe': rpe,
    'is_failure': isFailure ? 1 : 0,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SetEntry.fromMap(Map<String, dynamic> m) => SetEntry(
    id: m['id'] as int?,
    sessionExerciseId: m['session_exercise_id'] as int,
    weight: (m['weight'] as num).toDouble(),
    reps: m['reps'] as int,
    rpe: m['rpe'] != null ? (m['rpe'] as num).toDouble() : null,
    isFailure: (m['is_failure'] as int) == 1,
    timestamp: DateTime.parse(m['timestamp'] as String),
  );

  SetEntry copyWith({
    int? id, int? sessionExerciseId, double? weight, int? reps,
    double? rpe, bool? isFailure, DateTime? timestamp,
  }) => SetEntry(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    rpe: rpe ?? this.rpe,
    isFailure: isFailure ?? this.isFailure,
    timestamp: timestamp ?? this.timestamp,
  );
}

// ============================================================
// SessionExercise — one exercise within a training session
// ============================================================
class SessionExercise {
  final int? id;
  final int sessionId;
  final int exerciseDefinitionId;
  final int orderIndex;
  final String exerciseName;   // denormalised for display
  final String muscleGroup;
  final List<SetEntry> sets;

  SessionExercise({
    this.id,
    required this.sessionId,
    required this.exerciseDefinitionId,
    required this.orderIndex,
    required this.exerciseName,
    required this.muscleGroup,
    List<SetEntry>? sets,
  }) : sets = sets ?? [];

  double get totalVolume => sets.fold(0.0, (s, e) => s + e.volume);
  int get setCount => sets.length;

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'exercise_definition_id': exerciseDefinitionId,
    'order_index': orderIndex,
    'exercise_name': exerciseName,
    'muscle_group': muscleGroup,
  };

  factory SessionExercise.fromMap(Map<String, dynamic> m) => SessionExercise(
    id: m['id'] as int?,
    sessionId: m['session_id'] as int,
    exerciseDefinitionId: m['exercise_definition_id'] as int,
    orderIndex: m['order_index'] as int,
    exerciseName: m['exercise_name'] as String,
    muscleGroup: m['muscle_group'] as String,
  );

  SessionExercise copyWith({List<SetEntry>? sets}) => SessionExercise(
    id: id,
    sessionId: sessionId,
    exerciseDefinitionId: exerciseDefinitionId,
    orderIndex: orderIndex,
    exerciseName: exerciseName,
    muscleGroup: muscleGroup,
    sets: sets ?? this.sets,
  );
}

// ============================================================
// TrainingSession — one complete workout
// ============================================================
class TrainingSession {
  final int? id;
  final int? cycleId;
  final DateTime date;
  final DateTime? endTime;
  final String? notes;

  const TrainingSession({
    this.id,
    this.cycleId,
    required this.date,
    this.endTime,
    this.notes,
  });

  Duration? get duration => endTime != null ? endTime!.difference(date) : null;
  bool get isCompleted => endTime != null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'cycle_id': cycleId,
    'date': date.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'notes': notes,
  };

  factory TrainingSession.fromMap(Map<String, dynamic> m) => TrainingSession(
    id: m['id'] as int?,
    cycleId: m['cycle_id'] as int?,
    date: DateTime.parse(m['date'] as String),
    endTime: m['end_time'] != null ? DateTime.parse(m['end_time'] as String) : null,
    notes: m['notes'] as String?,
  );
}
