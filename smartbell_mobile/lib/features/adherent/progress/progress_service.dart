import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/measurement.dart';

class ProgressService {
  static const _prefsKey = 'smartbell_measurements_';

  Future<List<Measurement>> getMeasurements(int memberId) async {
    try {
      final res = await DioClient.instance.dio
          .get('/members/$memberId/measurements');
      final raw = res.data;
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['content'] ?? raw['data'] ?? []) : []);
      final fromApi = (list as List)
          .map((j) => Measurement.fromJson(j as Map<String, dynamic>))
          .toList();

      // Keep local-only entries (no server id) so nothing is lost
      final local = await _loadLocal(memberId);
      final serverIds = fromApi.map((m) => m.id).whereType<int>().toSet();
      final localOnly =
          local.where((m) => m.id == null || !serverIds.contains(m.id)).toList();

      final merged = [...fromApi, ...localOnly];
      merged.sort((a, b) => a.date.compareTo(b.date));

      // Persist merged state locally for offline use
      await _saveLocal(memberId, merged);
      return merged;
    } catch (_) {
      return _loadLocal(memberId);
    }
  }

  Future<Measurement> addMeasurement(int memberId, Measurement m) async {
    // Persist locally immediately for instant feedback
    final local = await _loadLocal(memberId);
    final withNew = [...local, m]..sort((a, b) => a.date.compareTo(b.date));
    await _saveLocal(memberId, withNew);

    try {
      final res = await DioClient.instance.dio
          .post('/members/$memberId/measurements', data: m.toJson());
      final saved = Measurement.fromJson(res.data as Map<String, dynamic>);

      // Replace provisional entry with server version
      final updated = withNew.map(
        (x) => (x.id == null &&
                x.date == m.date &&
                x.weight == m.weight)
            ? saved
            : x,
      ).toList();
      await _saveLocal(memberId, updated);
      return saved;
    } catch (_) {
      // Server unavailable — local copy is sufficient
      return m;
    }
  }

  Future<void> deleteMeasurement(int memberId, Measurement m) async {
    final local = await _loadLocal(memberId);
    final updated = local
        .where((x) =>
            !(x.date == m.date &&
              x.weight == m.weight &&
              x.height == m.height))
        .toList();
    await _saveLocal(memberId, updated);

    if (m.id != null) {
      try {
        await DioClient.instance.dio
            .delete('/members/$memberId/measurements/${m.id}');
      } catch (_) {}
    }
  }

  // ── Local storage helpers ─────────────────────────────────────────────────

  Future<List<Measurement>> _loadLocal(int memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString('$_prefsKey$memberId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((j) => Measurement.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocal(int memberId, List<Measurement> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKey$memberId',
      jsonEncode(list.map((m) => m.toJson()).toList()),
    );
  }
}
