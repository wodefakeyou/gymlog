import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gymlog.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        goal TEXT NOT NULL,
        activity_level REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cycles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        number INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE training_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER,
        date TEXT NOT NULL,
        end_time TEXT,
        notes TEXT,
        FOREIGN KEY (cycle_id) REFERENCES cycles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_definition_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES training_sessions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE set_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        rpe REAL,
        is_failure INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_exercise_id) REFERENCES session_exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Seed default data
    final p = UserProfile.defaultProfile;
    await db.insert('user_profile', p.toMap()..remove('id'));

    await db.insert('cycles', {
      'start_date': DateTime.now().toIso8601String(),
      'end_date': null,
      'number': 1,
    });

    for (final ex in kDefaultExercises) {
      await db.insert('exercise_definitions', {
        'name': ex['name'],
        'muscle_group': ex['muscleGroup'],
        'is_custom': 0,
      });
    }
  }

  // ── USER PROFILE ────────────────────────────────────────────
  Future<UserProfile?> getProfile() async {
    final d = await db;
    final rows = await d.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile p) async {
    final d = await db;
    if (p.id != null) {
      await d.update('user_profile', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    } else {
      await d.insert('user_profile', p.toMap()..remove('id'));
    }
  }

  // ── CYCLES ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getActiveCycle() async {
    final d = await db;
    final rows = await d.query('cycles',
        where: 'end_date IS NULL', orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllCycles() async {
    final d = await db;
    return d.query('cycles', orderBy: 'number DESC');
  }

  Future<int> createCycle(int number) async {
    final d = await db;
    return d.insert('cycles', {
      'start_date': DateTime.now().toIso8601String(),
      'end_date': null,
      'number': number,
    });
  }

  Future<void> closeCycle(int id) async {
    final d = await db;
    await d.update('cycles',
        {'end_date': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── SESSIONS ────────────────────────────────────────────────
  Future<int> createSession(int? cycleId) async {
    final d = await db;
    return d.insert('training_sessions', {
      'cycle_id': cycleId,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endSession(int id) async {
    final d = await db;
    await d.update('training_sessions',
        {'end_time': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50}) async {
    final d = await db;
    return d.query('training_sessions',
        where: 'end_time IS NOT NULL', orderBy: 'date DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getAllSessionsForCalendar() async {
    final d = await db;
    return d.query('training_sessions',
        where: 'end_time IS NOT NULL', orderBy: 'date ASC');
  }

  // ── EXERCISES ───────────────────────────────────────────────
  Future<List<ExerciseDefinition>> getExercises() async {
    final d = await db;
    final rows = await d.query('exercise_definitions',
        orderBy: 'muscle_group, name');
    return rows.map(ExerciseDefinition.fromMap).toList();
  }

  Future<int> addCustomExercise(String name, String muscleGroup) async {
    final d = await db;
    return d.insert('exercise_definitions', {
      'name': name,
      'muscle_group': muscleGroup,
      'is_custom': 1,
    });
  }

  Future<void> deleteExercise(int id) async {
    final d = await db;
    await d.delete('exercise_definitions', where: 'id = ?', whereArgs: [id]);
  }

  // ── SESSION EXERCISES ────────────────────────────────────────
  Future<int> addSessionExercise({
    required int sessionId,
    required int exerciseDefinitionId,
    required int orderIndex,
    required String exerciseName,
    required String muscleGroup,
  }) async {
    final d = await db;
    return d.insert('session_exercises', {
      'session_id': sessionId,
      'exercise_definition_id': exerciseDefinitionId,
      'order_index': orderIndex,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
    });
  }

  Future<List<Map<String, dynamic>>> getSessionExercises(int sessionId) async {
    final d = await db;
    return d.query('session_exercises',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'order_index');
  }

  Future<void> removeSessionExercise(int id) async {
    final d = await db;
    // Also delete its sets
    await d.rawDelete(
        'DELETE FROM set_entries WHERE session_exercise_id = ?', [id]);
    await d.delete('session_exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ── SETS ────────────────────────────────────────────────────
  Future<int> insertSet(SetEntry s) async {
    final d = await db;
    final map = s.toMap()..remove('id');
    return d.insert('set_entries', map);
  }

  Future<void> deleteSet(int id) async {
    final d = await db;
    await d.delete('set_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SetEntry>> getSets(int sessionExerciseId) async {
    final d = await db;
    final rows = await d.query('set_entries',
        where: 'session_exercise_id = ?',
        whereArgs: [sessionExerciseId],
        orderBy: 'timestamp');
    return rows.map(SetEntry.fromMap).toList();
  }

  /// Last sets for an exercise def (auto-fill suggestion)
  Future<List<SetEntry>> getLastSets(int exerciseDefinitionId) async {
    final d = await db;
    final seRows = await d.rawQuery('''
      SELECT se.id FROM session_exercises se
      JOIN training_sessions ts ON se.session_id = ts.id
      WHERE se.exercise_definition_id = ?
        AND ts.end_time IS NOT NULL
      ORDER BY ts.date DESC LIMIT 1
    ''', [exerciseDefinitionId]);
    if (seRows.isEmpty) return [];
    return getSets(seRows.first['id'] as int);
  }

  /// PR — max weight ever lifted for an exercise
  Future<double?> getPR(int exerciseDefinitionId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT MAX(s.weight) AS max_w FROM set_entries s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      WHERE se.exercise_definition_id = ?
    ''', [exerciseDefinitionId]);
    if (rows.isEmpty || rows.first['max_w'] == null) return null;
    return (rows.first['max_w'] as num).toDouble();
  }

  /// All PRs per exercise
  Future<List<Map<String, dynamic>>> getAllPRs() async {
    final d = await db;
    return d.rawQuery('''
      SELECT ed.name, ed.muscle_group, MAX(s.weight) AS max_w, MAX(s.reps * s.weight) AS max_vol
      FROM set_entries s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercise_definitions ed ON se.exercise_definition_id = ed.id
      GROUP BY ed.id
      ORDER BY max_w DESC
    ''');
  }

  /// Muscles trained in a cycle (for auto-cycle-advance logic)
  Future<Set<String>> getMusclesInCycle(int cycleId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT DISTINCT se.muscle_group FROM session_exercises se
      JOIN training_sessions ts ON se.session_id = ts.id
      WHERE ts.cycle_id = ?
    ''', [cycleId]);
    return rows.map((r) => r['muscle_group'] as String).toSet();
  }

  /// Progress history for a specific exercise (for chart)
  Future<List<Map<String, dynamic>>> getExerciseProgress(
      int exerciseDefinitionId) async {
    final d = await db;
    return d.rawQuery('''
      SELECT ts.date, MAX(s.weight) AS max_w, SUM(s.weight * s.reps) AS volume
      FROM set_entries s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN training_sessions ts ON se.session_id = ts.id
      WHERE se.exercise_definition_id = ?
        AND ts.end_time IS NOT NULL
      GROUP BY ts.id
      ORDER BY ts.date ASC
    ''', [exerciseDefinitionId]);
  }

  // ── WEIGHT LOG ───────────────────────────────────────────────
  Future<void> logWeight(double weight) async {
    final d = await db;
    await d.insert('weight_log', {
      'weight': weight,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWeightLog() async {
    final d = await db;
    return d.query('weight_log', orderBy: 'date ASC');
  }

  // ── EXPORT ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> exportAll() async {
    final d = await db;
    return {
      'app': 'GymLog',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'user_profile': await d.query('user_profile'),
      'cycles': await d.query('cycles'),
      'training_sessions': await d.query('training_sessions'),
      'exercise_definitions': await d.query('exercise_definitions'),
      'session_exercises': await d.query('session_exercises'),
      'set_entries': await d.query('set_entries'),
      'weight_log': await d.query('weight_log'),
    };
  }

  // ── STATS HELPERS ────────────────────────────────────────────
  Future<int> getSessionCount() async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT COUNT(*) AS c FROM training_sessions WHERE end_time IS NOT NULL');
    return r.first['c'] as int;
  }

  Future<int> getCycleCount() async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) AS c FROM cycles');
    return r.first['c'] as int;
  }

  Future<double> getTotalVolume() async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT SUM(weight * reps) AS v FROM set_entries');
    if (r.isEmpty || r.first['v'] == null) return 0;
    return (r.first['v'] as num).toDouble();
  }
}
