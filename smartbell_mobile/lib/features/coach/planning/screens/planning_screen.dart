import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  int _selectedDay = 0; // 0 = Tous

  static const _dayLabels = ['Tous', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _dayKeys   = ['ALL','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
  static const _dayColors = [
    Color(0xFFE5A01A),
    Color(0xFFE57373), Color(0xFF81C784), Color(0xFF64B5F6),
    Color(0xFFFFB74D), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFFF06292),
  ];

  List<Map<String, dynamic>> get _filtered => _selectedDay == 0
      ? _courses
      : _courses.where((c) => (c['dayOfWeek'] ?? '').toString().toUpperCase() == _dayKeys[_selectedDay]).toList();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio    = DioClient.instance.dio;
      final user   = context.read<AuthProvider>().user;
      if (user == null) { setState(() => _loading = false); return; }

      // Récupérer l'id coach depuis le userId
      final coachRes = await dio.get(ApiConstants.coachByUser(user.id));
      final coachId  = (coachRes.data['id'] ?? 0).toInt();

      // Charger uniquement les cours de CE coach
      final res  = await dio.get(
        '${ApiConstants.courses}/coach/$coachId',
        queryParameters: {'size': 100},
      );
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _courses = List<Map<String, dynamic>>.from(list); _loading = false; });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  String _fullDay(String? key) {
    const m = {
      'MONDAY': 'Lundi', 'TUESDAY': 'Mardi', 'WEDNESDAY': 'Mercredi',
      'THURSDAY': 'Jeudi', 'FRIDAY': 'Vendredi', 'SATURDAY': 'Samedi', 'SUNDAY': 'Dimanche',
    };
    return m[key?.toUpperCase()] ?? (key ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          // ── Dark header ──
          Container(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Text(
                      'Planning',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Day filter chips
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      itemCount: _dayLabels.length,
                      itemBuilder: (_, i) {
                        final sel = _selectedDay == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? _dayColors[i] : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _dayLabels[i],
                              style: TextStyle(
                                color: sel ? Colors.black : const Color(0xFF888888),
                                fontSize: 12,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _load,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]))
                    : RefreshIndicator(
                        color: const Color(0xFFE5A01A),
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? const Center(
                                child: Text('Aucun cours pour ce jour', style: TextStyle(color: Color(0xFF888888))),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final c       = _filtered[i];
                                  final dayKey  = (c['dayOfWeek'] ?? '').toString().toUpperCase();
                                  final dayIdx  = _dayKeys.indexOf(dayKey).clamp(0, 7);
                                  final current = (c['currentParticipants'] ?? 0).toInt();
                                  final max     = (c['maxParticipants'] ?? 0).toInt();
                                  final isFull  = max > 0 && current >= max;
                                  final barColor = _dayColors[dayIdx];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 5, height: 110,
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(14),
                                              bottomLeft: Radius.circular(14),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(child: Text(
                                                      c['name'] ?? 'Cours',
                                                      style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15),
                                                    )),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: barColor.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        _fullDay(c['dayOfWeek']),
                                                        style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(children: [
                                                  const Icon(Icons.schedule, size: 13, color: Color(0xFFBBBBBB)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${c['startTime'] ?? ''} – ${c['endTime'] ?? ''}',
                                                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                                                  ),
                                                  if (c['location'] != null) ...[
                                                    const SizedBox(width: 10),
                                                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFFBBBBBB)),
                                                    const SizedBox(width: 2),
                                                    Expanded(child: Text(
                                                      c['location'].toString(),
                                                      style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                                                      overflow: TextOverflow.ellipsis,
                                                    )),
                                                  ],
                                                ]),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(children: [
                                                      const Icon(Icons.people_outline, size: 14, color: Color(0xFF888888)),
                                                      const SizedBox(width: 4),
                                                      Text('$current / $max inscrits', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                                                    ]),
                                                    isFull
                                                        ? _Pill(label: 'Complet',        bg: const Color(0xFFFCEBEB), fg: const Color(0xFFA32D2D))
                                                        : _Pill(label: '${max - current} places', bg: const Color(0xFFEAF3DE), fg: const Color(0xFF3B6D11)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
