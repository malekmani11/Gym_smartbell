import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
import '../models/training_program.dart';
import '../offline_training_repository.dart';
import '../services/training_service.dart';

class TrainingProvider extends ChangeNotifier {
  final TrainingService _service = TrainingService();
  final OfflineTrainingRepository _offlineRepo = OfflineTrainingRepository();

  List<TrainingProgram> _programs = [];
  TrainingProgram? _active;
  int _currentExerciseIndex = 0;
  bool _restActive = false;
  bool _loading = false;
  String? _error;

  List<TrainingProgram> get programs          => _programs;
  TrainingProgram?       get active           => _active;
  int                    get currentIndex     => _currentExerciseIndex;
  bool                   get restActive       => _restActive;
  bool                   get loading          => _loading;
  String?                get error            => _error;

  Exercise? get currentExercise =>
      _active != null && _active!.exercises.isNotEmpty
          ? _active!.exercises[_currentExerciseIndex]
          : null;

  bool get isLastExercise =>
      _active == null || _currentExerciseIndex >= _active!.exercises.length - 1;

  Future<void> loadForMember(int memberId) async {
    _setLoading(true);
    try {
      // Uses OfflineTrainingRepository: fetches fresh from API when online,
      // falls back to Hive cache when offline.
      _programs = await _offlineRepo.getTrainingPrograms(memberId);
      if (_active == null) {
        _active = _programs.isNotEmpty ? _programs.first : null;
      }
      _currentExerciseIndex = 0;
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
    }
  }

  Future<void> loadForCoach(int coachId) async {
    _setLoading(true);
    try {
      _programs = await _service.getProgramsByCoach(coachId);
      _setLoading(false);
    } catch (e) {
      _error = DioClient.errorMessage(e);
      _setLoading(false);
    }
  }

  void markCurrentDone() {
    if (_active == null) return;
    _active!.exercises[_currentExerciseIndex].done = true;
    _restActive = true;
    notifyListeners();
  }

  void onRestFinished() {
    _restActive = false;
    if (!isLastExercise) {
      _currentExerciseIndex++;
    }
    notifyListeners();
  }

  void resetActive() {
    _active = null;
    _currentExerciseIndex = 0;
    _restActive = false;
    notifyListeners();
  }

  void selectProgram(TrainingProgram p) {
    _active = p;
    _currentExerciseIndex = 0;
    _restActive = false;
    for (final ex in p.exercises) {
      ex.done = false;
    }
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
