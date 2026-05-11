import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';
import '../utils/nutrition_calc.dart';

// ─────────────────────────────────────────────────────────────
// Simple data providers (async reads from DB)
// ─────────────────────────────────────────────────────────────

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  return DbHelper.instance.getProfile();
});

final nutritionProvider = FutureProvider<NutritionTarget?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  return NutritionCalculator.calculate(profile);
});

final exercisesProvider = FutureProvider<List<ExerciseDefinition>>((ref) async {
  return DbHelper.instance.getExercises();
});

final activeCycleProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return DbHelper.instance.getActiveCycle();
});

final recentSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DbHelper.instance.getSessions(limit: 20);
});

final allSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DbHelper.instance.getAllSessionsForCalendar();
});

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sessions = await DbHelper.instance.getSessionCount();
  final cycles   = await DbHelper.instance.getCycleCount();
  final volume   = await DbHelper.instance.getTotalVolume();
  final prs      = await DbHelper.instance.getAllPRs();
  return {
    'sessions': sessions,
    'cycles': cycles,
    'totalVolume': volume,
    'prs': prs,
  };
});

// ─────────────────────────────────────────────────────────────
// Active Session — mutable in-memory state
// ─────────────────────────────────────────────────────────────

class ActiveSession {
  final int? sessionId;
  final int? cycleId;
  final DateTime? startTime;
  final List<SessionExercise> exercises;
  final bool isActive;

  const ActiveSession({
    this.sessionId,
    this.cycleId,
    this.startTime,
    this.exercises = const [],
    this.isActive = false,
  });

  double get totalVolume =>
      exercises.fold(0.0, (s, e) => s + e.totalVolume);

  int get totalSets =>
      exercises.fold(0, (s, e) => s + e.setCount);

  ActiveSession copyWith({
    int? sessionId,
    int? cycleId,
    DateTime? startTime,
    List<SessionExercise>? exercises,
    bool? isActive,
  }) => ActiveSession(
    sessionId: sessionId ?? this.sessionId,
    cycleId:   cycleId   ?? this.cycleId,
    startTime: startTime ?? this.startTime,
    exercises: exercises ?? this.exercises,
    isActive:  isActive  ?? this.isActive,
  );
}

class SessionNotifier extends Notifier<ActiveSession> {
  @override
  ActiveSession build() => const ActiveSession();

  // ── START ────────────────────────────────────────────────────
  Future<void> start() async {
    final cycle = await DbHelper.instance.getActiveCycle();
    final cycleId = cycle?['id'] as int?;
    final sessionId = await DbHelper.instance.createSession(cycleId);

    state = ActiveSession(
      sessionId: sessionId,
      cycleId: cycleId,
      startTime: DateTime.now(),
      exercises: [],
      isActive: true,
    );
  }

  // ── ADD EXERCISE ────────────────────────────────────────────
  Future<void> addExercise(ExerciseDefinition def) async {
    if (state.sessionId == null) return;

    final seId = await DbHelper.instance.addSessionExercise(
      sessionId: state.sessionId!,
      exerciseDefinitionId: def.id!,
      orderIndex: state.exercises.length,
      exerciseName: def.name,
      muscleGroup: def.muscleGroup,
    );

    // Auto-fill suggestion from last session
    final lastSets = await DbHelper.instance.getLastSets(def.id!);

    final se = SessionExercise(
      id: seId,
      sessionId: state.sessionId!,
      exerciseDefinitionId: def.id!,
      orderIndex: state.exercises.length,
      exerciseName: def.name,
      muscleGroup: def.muscleGroup,
      sets: [], // user still needs to confirm each set
    );

    // Store last sets as a hint (we attach them separately)
    final updated = [...state.exercises, se];
    state = state.copyWith(exercises: updated);

    // Return last sets so UI can pre-fill weight/reps fields
    // (passed back via a side-channel — we store them on the notifier for simplicity)
    _lastSetsHint[seId] = lastSets;
  }

  // Last sets hint cache for auto-fill
  final Map<int, List<SetEntry>> _lastSetsHint = {};
  List<SetEntry> getLastSetsHint(int seId) => _lastSetsHint[seId] ?? [];

  // ── ADD SET ─────────────────────────────────────────────────
  Future<bool> addSet({
    required int seId,
    required double weight,
    required int reps,
    double? rpe,
    bool isFailure = false,
  }) async {
    final entry = SetEntry(
      sessionExerciseId: seId,
      weight: weight,
      reps: reps,
      rpe: rpe,
      isFailure: isFailure,
    );
    final id = await DbHelper.instance.insertSet(entry);
    final newSet = SetEntry(
      id: id,
      sessionExerciseId: seId,
      weight: weight,
      reps: reps,
      rpe: rpe,
      isFailure: isFailure,
    );

    // Check PR
    final pr = await DbHelper.instance.getPR(
      state.exercises.firstWhere((e) => e.id == seId).exerciseDefinitionId,
    );
    final isNewPR = pr == null || weight > pr;

    final updated = state.exercises.map((ex) {
      if (ex.id == seId) {
        return ex.copyWith(sets: [...ex.sets, newSet]);
      }
      return ex;
    }).toList();
    state = state.copyWith(exercises: updated);
    return isNewPR;
  }

  // ── DELETE SET ───────────────────────────────────────────────
  Future<void> deleteSet(int seId, int setId) async {
    await DbHelper.instance.deleteSet(setId);
    final updated = state.exercises.map((ex) {
      if (ex.id == seId) {
        return ex.copyWith(
            sets: ex.sets.where((s) => s.id != setId).toList());
      }
      return ex;
    }).toList();
    state = state.copyWith(exercises: updated);
  }

  // ── REMOVE EXERCISE ─────────────────────────────────────────
  Future<void> removeExercise(int seId) async {
    await DbHelper.instance.removeSessionExercise(seId);
    final updated = state.exercises.where((e) => e.id != seId).toList();
    state = state.copyWith(exercises: updated);
  }

  // ── END SESSION ─────────────────────────────────────────────
  Future<void> end() async {
    if (state.sessionId == null) return;
    await DbHelper.instance.endSession(state.sessionId!);

    // Auto-advance cycle when all required muscle groups covered
    if (state.cycleId != null) {
      final muscles = await DbHelper.instance.getMusclesInCycle(state.cycleId!);
      const required = {'chest', 'back', 'legs', 'shoulders'};
      if (required.every(muscles.contains)) {
        await DbHelper.instance.closeCycle(state.cycleId!);
        final allCycles = await DbHelper.instance.getAllCycles();
        final nextNum = (allCycles.isNotEmpty
            ? allCycles.first['number'] as int
            : 0) + 1;
        await DbHelper.instance.createCycle(nextNum);
      }
    }

    _lastSetsHint.clear();
    state = const ActiveSession();
  }

  // ── DISCARD ─────────────────────────────────────────────────
  void discard() {
    _lastSetsHint.clear();
    state = const ActiveSession();
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, ActiveSession>(SessionNotifier.new);
