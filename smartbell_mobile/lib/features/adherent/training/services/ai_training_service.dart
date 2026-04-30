import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/ai_training_request.dart';
import '../models/training_program.dart';

class AiTrainingService {
  /// Main entry point — tries backend proxy first, falls back to local generator.
  Future<TrainingProgram> generateProgram(AiTrainingRequest req) async {
    try {
      return await _generateViaBackend(req);
    } catch (_) {
      // Backend not available → generate locally
      return _generateLocally(req);
    }
  }

  // ── 1. Backend proxy (Spring Boot calls Claude on server-side, no CORS) ─────
  Future<TrainingProgram> _generateViaBackend(AiTrainingRequest req) async {
    final res = await DioClient.instance.dio.post(
      '/ai/training/generate',
      data: req.toJson(),
      options: Options(sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 60)),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return TrainingProgram.fromJson(data);
    // Backend may return a JSON string
    return TrainingProgram.fromJson(jsonDecode(data.toString()));
  }

  // ── 2. Local intelligent generator (works offline, no CORS) ─────────────────
  TrainingProgram _generateLocally(AiTrainingRequest req) {
    final exercises = _selectExercises(req);
    final name = _programName(req);
    final note = _coachNote(req);

    return TrainingProgram(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      description: 'Programme généré par IA selon ton profil',
      coachNote: note,
      exercises: exercises,
    );
  }

  // ── Exercise database ────────────────────────────────────────────────────────

  String _programName(AiTrainingRequest req) {
    const goals = {
      'PERTE_DE_POIDS':  'Programme Perte de Poids',
      'PRISE_DE_MUSCLE': 'Programme Hypertrophie',
      'ENDURANCE':       'Programme Endurance',
      'FORME_GENERALE':  'Programme Forme Générale',
    };
    const levels = {'DEBUTANT': 'Débutant', 'INTERMEDIAIRE': 'Intermédiaire', 'AVANCE': 'Avancé'};
    return '${goals[req.goal] ?? 'Programme'} — ${levels[req.level] ?? req.level}';
  }

  String _coachNote(AiTrainingRequest req) {
    final bmi    = req.bmi;
    final days   = req.sessionsPerWeek;
    final buffer = StringBuffer();

    // BMI advice
    if (bmi < 18.5) {
      buffer.write('Ton IMC indique une corpulence faible. Concentre-toi sur la prise de masse musculaire et une alimentation riche en protéines. ');
    } else if (bmi < 25) {
      buffer.write('Ton IMC est idéal. Tu peux optimiser tes performances et sculpter ta silhouette. ');
    } else if (bmi < 30) {
      buffer.write('Associe ce programme à une alimentation équilibrée. La régularité est la clé ! ');
    } else {
      buffer.write('Commence progressivement, écoute ton corps. Combine ce programme avec un suivi nutritionnel. ');
    }

    // Sessions advice
    if (days >= 5) {
      buffer.write('$days séances/semaine est excellent — pense à bien récupérer et dors 8h minimum.');
    } else if (days >= 3) {
      buffer.write('$days séances/semaine est un rythme idéal pour progresser. Maintiens la régularité.');
    } else {
      buffer.write('$days séance(s)/semaine est un bon début. Augmente progressivement quand tu te sentiras prêt.');
    }

    // Injuries
    if (req.injuries != null && req.injuries!.isNotEmpty) {
      buffer.write(' ⚠️ Attention à tes restrictions : ${req.injuries}. Consulte un kiné si besoin.');
    }

    return buffer.toString();
  }

  List<Exercise> _selectExercises(AiTrainingRequest req) {
    final isGym    = req.equipment != 'SANS_EQUIPEMENT';
    final isSalle  = req.equipment == 'SALLE';
    final adv      = req.level == 'AVANCE';
    final inter    = req.level == 'INTERMEDIAIRE';

    // Sets/reps based on goal
    int sets, reps, rest;
    switch (req.goal) {
      case 'PRISE_DE_MUSCLE':
        sets = adv ? 5 : (inter ? 4 : 3); reps = adv ? 8 : 10; rest = 90; break;
      case 'PERTE_DE_POIDS':
        sets = 3; reps = adv ? 15 : 12; rest = 45; break;
      case 'ENDURANCE':
        sets = 3; reps = adv ? 20 : 15; rest = 30; break;
      default: // FORME_GENERALE
        sets = 3; reps = 12; rest = 60;
    }

    final pool = _buildPool(req, isGym, isSalle, sets, reps, rest);

    // Select 6–8 exercises
    final count = req.level == 'DEBUTANT' ? 6 : (req.level == 'INTERMEDIAIRE' ? 7 : 8);
    return pool.take(count).toList();
  }

  List<Exercise> _buildPool(AiTrainingRequest req, bool isGym, bool isSalle, int sets, int reps, int rest) {
    final goal  = req.goal;
    final adv   = req.level == 'AVANCE';
    final mid   = req.level == 'INTERMEDIAIRE';

    // Weight estimates (0 = bodyweight)
    double chest = isSalle ? (adv ? 80 : (mid ? 60 : 40)) : 0;
    double back  = isSalle ? (adv ? 70 : (mid ? 50 : 30)) : 0;
    double legs  = isSalle ? (adv ? 100 : (mid ? 70 : 50)) : 0;
    double shoulder = isSalle ? (adv ? 30 : (mid ? 20 : 12)) : 0;

    if (goal == 'PERTE_DE_POIDS' || goal == 'ENDURANCE') {
      return [
        Exercise(id: 1,  name: 'Burpees',              sets: sets, reps: reps,     weight: 0,        restSeconds: rest),
        Exercise(id: 2,  name: 'Squat sauté',           sets: sets, reps: reps,     weight: 0,        restSeconds: rest),
        Exercise(id: 3,  name: isGym ? 'Rameur (500m)' : 'Mountain climbers', sets: sets, reps: isGym ? 1 : reps, weight: 0, restSeconds: rest),
        Exercise(id: 4,  name: 'Fentes alternées',      sets: sets, reps: reps,     weight: legs * 0.3, restSeconds: rest),
        Exercise(id: 5,  name: 'Jumping jacks',         sets: sets, reps: reps + 5, weight: 0,        restSeconds: rest),
        Exercise(id: 6,  name: 'Pompes',                sets: sets, reps: reps,     weight: 0,        restSeconds: rest),
        Exercise(id: 7,  name: 'Gainage planche',       sets: sets, reps: 1,        weight: 0,        restSeconds: 30),
        Exercise(id: 8,  name: isGym ? 'Vélo stationnaire (10 min)' : 'Corde à sauter (3 min)', sets: 1, reps: 1, weight: 0, restSeconds: 60),
      ];
    }

    if (goal == 'PRISE_DE_MUSCLE') {
      return [
        Exercise(id: 1, name: isSalle ? 'Développé couché barre'   : 'Pompes lestées',    sets: sets, reps: reps, weight: chest,      restSeconds: rest),
        Exercise(id: 2, name: isSalle ? 'Squat barre'              : 'Squat bulgare',      sets: sets, reps: reps, weight: legs,       restSeconds: rest),
        Exercise(id: 3, name: isSalle ? 'Soulevé de terre'         : 'Hip thrust',         sets: sets, reps: reps, weight: legs * 1.2, restSeconds: rest + 30),
        Exercise(id: 4, name: isSalle ? 'Rowing barre'             : 'Rowing haltères',    sets: sets, reps: reps, weight: back,       restSeconds: rest),
        Exercise(id: 5, name: isSalle ? 'Développé militaire'      : 'Pike push-up',       sets: sets, reps: reps, weight: shoulder,   restSeconds: rest),
        Exercise(id: 6, name: isSalle ? 'Curl biceps haltères'     : 'Curl isométrique',   sets: sets, reps: reps, weight: shoulder * 0.6, restSeconds: rest),
        Exercise(id: 7, name: isSalle ? 'Extension triceps poulie' : 'Dips banc',          sets: sets, reps: reps, weight: 0,          restSeconds: rest),
        Exercise(id: 8, name: 'Crunch abdominaux',                                          sets: 3,    reps: 20,   weight: 0,          restSeconds: 40),
      ];
    }

    // FORME_GENERALE (default)
    return [
      Exercise(id: 1, name: 'Squat',                           sets: sets, reps: reps, weight: legs * 0.6, restSeconds: rest),
      Exercise(id: 2, name: isSalle ? 'Développé couché haltères' : 'Pompes',     sets: sets, reps: reps, weight: chest * 0.7, restSeconds: rest),
      Exercise(id: 3, name: isSalle ? 'Tirage vertical'        : 'Tractions (assistées)', sets: sets, reps: reps, weight: 0, restSeconds: rest),
      Exercise(id: 4, name: 'Fentes',                          sets: sets, reps: reps, weight: legs * 0.3, restSeconds: rest),
      Exercise(id: 5, name: isSalle ? 'Presse à épaules'      : 'Pike push-up',          sets: sets, reps: reps, weight: shoulder, restSeconds: rest),
      Exercise(id: 6, name: 'Gainage planche',                 sets: 3,    reps: 1,   weight: 0,          restSeconds: 30),
      Exercise(id: 7, name: isSalle ? 'Cardio (tapis 10min)'  : 'Sauts genoux haut',      sets: 3,    reps: 20,  weight: 0,          restSeconds: 40),
      Exercise(id: 8, name: 'Étirements & mobilité',           sets: 1,    reps: 1,   weight: 0,          restSeconds: 60),
    ];
  }
}
