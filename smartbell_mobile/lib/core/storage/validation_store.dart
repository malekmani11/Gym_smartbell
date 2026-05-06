import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local store (SharedPreferences) for AI-generated programs/plans awaiting
/// coach validation.  Works fully offline; both member and coach share the same
/// device in a typical PFE demo.
class ValidationStore {
  static const _trainingKey  = 'gym_pending_training';
  static const _nutritionKey = 'gym_pending_nutrition';

  // ── Training ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllTrainings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trainingKey) ?? '[]';
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  static Future<void> submitTraining({
    required int    memberId,
    required String memberName,
    required Map<String, dynamic> program,
    int? coachId,
  }) async {
    final list = await getAllTrainings();
    // Keep at most one PENDING per member (replace old one)
    list.removeWhere((e) => e['memberId'] == memberId && e['status'] == 'PENDING');
    list.add({
      'id':          'tr_${memberId}_${DateTime.now().millisecondsSinceEpoch}',
      'memberId':    memberId,
      'memberName':  memberName,
      'coachId':     coachId,
      'submittedAt': DateTime.now().toIso8601String(),
      'status':      'PENDING',
      'coachNote':   '',
      'program':     program,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trainingKey, jsonEncode(list));
  }

  static Future<Map<String, dynamic>?> getLatestTrainingForMember(int memberId) async {
    final list = await getAllTrainings();
    final matches = list.where((e) => e['memberId'] == memberId).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) =>
        (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    return matches.first;
  }

  static Future<void> updateTrainingStatus(
    String id,
    String status, {
    String? coachNote,
  }) async {
    final list = await getAllTrainings();
    final idx  = list.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      list[idx]['status']      = status;
      if (coachNote != null) list[idx]['coachNote'] = coachNote;
      list[idx]['validatedAt'] = DateTime.now().toIso8601String();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trainingKey, jsonEncode(list));
  }

  // ── Nutrition ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllNutritions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_nutritionKey) ?? '[]';
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  static Future<void> submitNutrition({
    required int    memberId,
    required String memberName,
    required Map<String, dynamic> plan,
    int? coachId,
  }) async {
    final list = await getAllNutritions();
    list.removeWhere((e) => e['memberId'] == memberId && e['status'] == 'PENDING');
    list.add({
      'id':          'nu_${memberId}_${DateTime.now().millisecondsSinceEpoch}',
      'memberId':    memberId,
      'memberName':  memberName,
      'coachId':     coachId,
      'submittedAt': DateTime.now().toIso8601String(),
      'status':      'PENDING',
      'coachNote':   '',
      'plan':        plan,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionKey, jsonEncode(list));
  }

  static Future<Map<String, dynamic>?> getLatestNutritionForMember(int memberId) async {
    final list = await getAllNutritions();
    final matches = list.where((e) => e['memberId'] == memberId).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) =>
        (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    return matches.first;
  }

  static Future<void> updateNutritionStatus(
    String id,
    String status, {
    String? coachNote,
  }) async {
    final list = await getAllNutritions();
    final idx  = list.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      list[idx]['status']      = status;
      if (coachNote != null) list[idx]['coachNote'] = coachNote;
      list[idx]['validatedAt'] = DateTime.now().toIso8601String();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionKey, jsonEncode(list));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Trainings for a specific coach (by coachId).
  static Future<List<Map<String, dynamic>>> getTrainingsForCoach(int coachId) async {
    final all = await getAllTrainings();
    return all.where((e) => e['coachId'] == coachId).toList();
  }

  /// Nutritions for a specific coach (by coachId).
  static Future<List<Map<String, dynamic>>> getNutritionsForCoach(int coachId) async {
    final all = await getAllNutritions();
    return all.where((e) => e['coachId'] == coachId).toList();
  }

  /// Total number of items awaiting coach review.
  static Future<int> pendingCount() async {
    final trainings  = await getAllTrainings();
    final nutritions = await getAllNutritions();
    return trainings.where((e)  => e['status'] == 'PENDING').length
         + nutritions.where((e) => e['status'] == 'PENDING').length;
  }
}
