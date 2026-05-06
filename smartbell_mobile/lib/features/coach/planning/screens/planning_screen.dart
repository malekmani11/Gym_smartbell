import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/gym_badge.dart';

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

  List<Map<String, dynamic>> get _filtered => _selectedDay == 0
      ? _courses
      : _courses.where((c) => (c['dayOfWeek'] ?? '').toString().toUpperCase() == _dayKeys[_selectedDay]).toList();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await DioClient.instance.dio.get(ApiConstants.courses, queryParameters: {'size': 100, 'active': true});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() { _courses = List<Map<String, dynamic>>.from(list); _loading = false; });
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  static const _dayColors = [
    AppTheme.primary,
    Color(0xFFE57373), Color(0xFF81C784), Color(0xFF64B5F6),
    Color(0xFFFFB74D), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFFF06292),
  ];

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Planning'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                      color: sel ? _dayColors[i] : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _dayColors[i] : AppTheme.border, width: 0.5),
                    ),
                    child: Text(_dayLabels[i], style: TextStyle(
                      color: sel ? Colors.black : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                ]))
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Aucun cours pour ce jour', style: TextStyle(color: AppTheme.textSecondary)))
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

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5, height: 110,
                                      decoration: BoxDecoration(
                                        color: _dayColors[dayIdx],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(14), bottomLeft: Radius.circular(14),
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
                                                Expanded(child: Text(c['name'] ?? 'Cours', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(color: _dayColors[dayIdx].withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                                                  child: Text(_fullDay(c['dayOfWeek']), style: TextStyle(color: _dayColors[dayIdx], fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              const Icon(Icons.schedule, size: 13, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Text('${c['startTime'] ?? ''} – ${c['endTime'] ?? ''}',
                                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                              if (c['location'] != null) ...[
                                                const SizedBox(width: 10),
                                                const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                                                const SizedBox(width: 2),
                                                Expanded(child: Text(c['location'].toString(),
                                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ],
                                            ]),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(children: [
                                                  const Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                                                  const SizedBox(width: 4),
                                                  Text('$current / $max inscrits',
                                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                                ]),
                                                isFull
                                                    ? GymBadge(text: 'Complet', type: BadgeType.red)
                                                    : GymBadge(text: '${max - current} places', type: BadgeType.green),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
