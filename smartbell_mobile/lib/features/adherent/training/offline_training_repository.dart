import '../../../core/constants/api_constants.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_service.dart';
import '../../../shared/models/cached_program.dart';
import 'models/training_program.dart';

class OfflineTrainingRepository {
  // ── Public API ────────────────────────────────────────────────────────────

  Future<List<TrainingProgram>> getTrainingPrograms(int memberId) async {
    final isOnline =
        await ConnectivityService.instance.checkConnectivity();

    if (isOnline) {
      try {
        final programs = await _fetchFromApi(memberId);
        await _cache(programs);
        return programs;
      } catch (_) {
        return _fromCache();
      }
    } else {
      return _fromCache();
    }
  }

  /// Forces a fresh fetch from the API and updates the cache.
  Future<void> forceSync(int memberId) async {
    final programs = await _fetchFromApi(memberId);
    await _cache(programs);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<TrainingProgram>> _fetchFromApi(int memberId) async {
    final res = await DioClient.instance.dio
        .get(ApiConstants.trainingByMember(memberId));
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['content'] ?? [data]) : []);
    return (list as List)
        .map((e) => TrainingProgram.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _cache(List<TrainingProgram> programs) async {
    final cached = programs.map(_toCached).toList();
    await HiveService.savePrograms(cached);
    await HiveService.setLastSyncDate(DateTime.now());
  }

  List<TrainingProgram> _fromCache() {
    final cached = HiveService.getPrograms();
    if (cached.isEmpty) {
      throw Exception(
        'Aucun programme en cache. '
        'Connectez-vous pour synchroniser votre programme.',
      );
    }
    return cached.map(_toTrainingProgram).toList();
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static CachedProgram _toCached(TrainingProgram p) => CachedProgram(
        programId: p.id,
        name:      p.name,
        status:    'cached',
        exercises: p.exercises.map(_toCachedEx).toList(),
      );

  static CachedExercise _toCachedEx(Exercise ex) => CachedExercise(
        exerciseId:  ex.id,
        name:        ex.name,
        sets:        ex.sets,
        reps:        ex.reps,
        restSeconds: ex.restSeconds,
      );

  static TrainingProgram _toTrainingProgram(CachedProgram c) => TrainingProgram(
        id:        c.programId,
        name:      c.name,
        exercises: c.exercises.map(_toExercise).toList(),
      );

  static Exercise _toExercise(CachedExercise c) => Exercise(
        id:          c.exerciseId,
        name:        c.name,
        sets:        c.sets,
        reps:        c.reps,
        restSeconds: c.restSeconds,
      );
}
