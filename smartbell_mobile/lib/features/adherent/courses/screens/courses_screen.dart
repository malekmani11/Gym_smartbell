import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  final _service = CourseService();
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  int _selectedDay = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';
  final Set<int> _reserving = {};

  static const _dayLabels = ['Tous', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _dayKeys   = ['ALL', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

  static const _dayColors = [
    Color(0xFFE5A01A),
    Color(0xFFE57373), Color(0xFF81C784), Color(0xFF64B5F6),
    Color(0xFFFFB74D), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFFF06292),
  ];

  List<Course> get _filtered {
    var list = _courses;
    if (_selectedDay > 0) {
      list = list.where((c) => c.dayOfWeek?.toUpperCase() == _dayKeys[_selectedDay]).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.coachName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _courses = await _service.getCourses();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = DioClient.errorMessage(e); _loading = false; });
    }
  }

  Future<void> _reserve(Course course) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _reserving.add(course.id));
    try {
      final memberRes = await DioClient.instance.dio.get('/members/user/${user.id}');
      final memberId  = (memberRes.data['id'] ?? 0).toInt();
      await _service.reserve(courseId: course.id, memberId: memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Réservation confirmée pour "${course.name}"'),
          backgroundColor: const Color(0xFF3B6D11),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(DioClient.errorMessage(e)),
          backgroundColor: const Color(0xFFA32D2D),
        ));
      }
    } finally {
      setState(() => _reserving.remove(course.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cours disponibles',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            // Search field
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un cours, coach...',
                  hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFBBBBBB), size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            // Day chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _dayLabels.length,
                itemBuilder: (_, i) {
                  final sel = _selectedDay == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          color: sel ? const Color(0xFFE5A01A) : const Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final course = _filtered[i];
                            final dayIdx = _dayKeys.indexOf(course.dayOfWeek?.toUpperCase() ?? '').clamp(0, 7);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CourseCard(
                                course: course,
                                accent: _dayColors[dayIdx],
                                isReserving: _reserving.contains(course.id),
                                onReserve: () => _reserve(course),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, color: Color(0xFFBBBBBB), size: 48),
        SizedBox(height: 12),
        Text('Aucun cours trouvé', style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFFA32D2D), size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF888888), fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFE5A01A),
              elevation: 0,
            ),
          ),
        ]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color accent;
  final bool isReserving;
  final VoidCallback onReserve;
  const _CourseCard({required this.course, required this.accent, required this.isReserving, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final fillPct = course.maxParticipants > 0
        ? ((course.currentParticipants ?? 0) / course.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sombre
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(child: Text(
                course.dayLabel.isEmpty ? '' : course.dayLabel.toUpperCase(),
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              )),
              if (course.dayOfWeek != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course.dayLabel,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(course.name, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500, fontSize: 14)),
                  if (course.coachName != null)
                    Text(course.coachName!, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  if (course.startTime != null)
                    Text(course.timeRange, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
                ])),
              ]),
              const SizedBox(height: 10),
              // Fill bar
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    course.isFull ? 'Complet' : '${course.spotsLeft} places',
                    style: TextStyle(
                      color: course.isFull ? const Color(0xFFA32D2D) : const Color(0xFF888888),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: fillPct,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFE8E8E8),
                      valueColor: AlwaysStoppedAnimation(
                        fillPct >= 1.0 ? const Color(0xFFA32D2D) : const Color(0xFFE5A01A),
                      ),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: course.isFull || isReserving ? null : onReserve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: course.isFull ? const Color(0xFFF0F0F0) : const Color(0xFFE5A01A),
                      foregroundColor: course.isFull ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A1A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: isReserving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
                        : Text(course.isFull ? 'Complet' : 'Réserver'),
                  ),
                ),
              ]),
            ]),
          ),
          // Bottom colored bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
