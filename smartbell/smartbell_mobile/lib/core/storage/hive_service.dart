import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/cached_program.dart';

class HiveService {
  static const _boxPrograms = 'training_programs';
  static const _boxPrefs    = 'user_prefs';
  static const _keyLastSync = 'last_sync_date';

  static Future<void> initHive() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedProgramAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedExerciseAdapter());
    }
    await Hive.openBox<CachedProgram>(_boxPrograms);
    await Hive.openBox<dynamic>(_boxPrefs);
  }

  static Box<CachedProgram> get _programs =>
      Hive.box<CachedProgram>(_boxPrograms);
  static Box<dynamic> get _prefs => Hive.box<dynamic>(_boxPrefs);

  // ── Programs ─────────────────────────────────────────────────────────────

  static Future<void> savePrograms(List<CachedProgram> programs) async {
    await _programs.clear();
    final entries = {for (final p in programs) p.programId: p};
    await _programs.putAll(entries);
  }

  static List<CachedProgram> getPrograms() => _programs.values.toList();

  static Future<void> clearPrograms() => _programs.clear();

  // ── Last sync date ────────────────────────────────────────────────────────

  static DateTime? get lastSyncDate {
    final iso = _prefs.get(_keyLastSync) as String?;
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  static Future<void> setLastSyncDate(DateTime date) =>
      _prefs.put(_keyLastSync, date.toIso8601String());
}
