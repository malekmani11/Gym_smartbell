import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/measurement.dart';

class ProgressService {
  static const _prefsKey = 'smartbell_measurements_';

  Future<List<Measurement>> getMeasurements(int memberId) async {
    // Measurements are stored locally only (no backend endpoint).
    // Using SharedPreferences avoids any API call that could trigger logout.
    return _loadLocal(memberId);
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
    // Prefer matching by server id; fallback to date+weight+height for local-only entries
    bool found = false;
    final updated = local.where((x) {
      if (!found && m.id != null && x.id == m.id) { found = true; return false; }
      if (!found && m.id == null && x.date == m.date && x.weight == m.weight && x.height == m.height) {
        found = true; return false;
      }
      return true;
    }).toList();
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
