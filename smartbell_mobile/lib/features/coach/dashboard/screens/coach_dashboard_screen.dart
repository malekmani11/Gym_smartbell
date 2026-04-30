import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/gym_badge.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen>
    with TickerProviderStateMixin {
  int _activeMembers = 0;
  int _todayCourses  = 0;
  int _monthHours    = 0;
  List<Map<String, dynamic>> _todayCoursesList = [];
  bool _loading = true;

  static const _days = [
    'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'
  ];

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }
    final dio = DioClient.instance.dio;
    final today = _days[DateTime.now().weekday - 1];

    try {
      try {
        final mRes = await dio.get(ApiConstants.members,
            queryParameters: {'size': 1});
        final mData = mRes.data;
        _activeMembers = (mData is Map
            ? (mData['totalElements'] ?? mData['total'] ?? 0)
            : 0)
            .toInt();
      } catch (_) {}

      try {
        final coachRes = await dio.get(ApiConstants.coachByUser(user.id));
        final coachId  = (coachRes.data['id'] ?? 0).toInt();
        if (coachId > 0) {
          final cRes = await dio.get(ApiConstants.courses,
              queryParameters: {'size': 100, 'active': true});
          final cData = cRes.data;
          final cList = cData is Map ? (cData['content'] ?? []) : (cData ?? []);
          final all = List<Map<String, dynamic>>.from(cList);
          _todayCoursesList = all
              .where((c) =>
                  (c['dayOfWeek'] ?? '').toString().toUpperCase() == today)
              .toList();
          _todayCourses = _todayCoursesList.length;
        }
      } catch (_) {}

      _monthHours = 0;
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final now  = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _pulseCtrl.stop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header banner ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF222222), Color(0xFF181818)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0x401D9E75), width: 0.5),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 20, right: 20, bottom: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coach ${user?.firstName ?? ''}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            now,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          GymBadge(text: 'Disponible', type: BadgeType.green),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              AppTheme.success.withValues(alpha: 0.22),
                              AppTheme.success.withValues(alpha: 0.06),
                            ]),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user?.initials ?? 'C',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0, top: 0,
                          child: disableAnimations
                              ? Container(
                                  width: 11, height: 11,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.background, width: 2),
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (_, __) => Container(
                                    width: 11, height: 11,
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withValues(alpha: _pulse.value),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.background, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.success.withValues(
                                              alpha: _pulse.value * 0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Stats ──
                    Row(children: [
                      Expanded(child: StatCard(
                        value: '$_activeMembers',
                        label: 'Membres actifs',
                        icon: Icons.people_outline,
                        color: AppTheme.primary,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                        value: '$_todayCourses',
                        label: 'Cours aujourd\'hui',
                        icon: Icons.today,
                        color: AppTheme.success,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                        value: '$_monthHours h',
                        label: 'Heures ce mois',
                        icon: Icons.timer_outlined,
                        color: AppTheme.info,
                      )),
                    ]),
                    const SizedBox(height: 24),

                    // ── Today's courses ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("COURS D'AUJOURD'HUI",
                            style: AppTheme.sectionTitle),
                        GestureDetector(
                          onTap: () => context.go('/coach/planning'),
                          child: const Text(
                            'Planning →',
                            style: TextStyle(
                                color: AppTheme.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_todayCoursesList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.border, width: 0.5),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Center(
                          child: Text(
                            'Aucun cours aujourd\'hui',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._todayCoursesList.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseTile(course: c),
                      )),
                    const SizedBox(height: 24),

                    // ── Quick actions ──
                    const Text('NAVIGATION RAPIDE',
                        style: AppTheme.sectionTitle),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: [
                        _NavCard(
                          icon: Icons.people_outline,
                          label: 'Mes membres',
                          color: AppTheme.primary,
                          path: '/coach/members',
                        ),
                        _NavCard(
                          icon: Icons.calendar_month,
                          label: 'Planning',
                          color: AppTheme.success,
                          path: '/coach/planning',
                        ),
                        _NavCard(
                          icon: Icons.fitness_center,
                          label: 'Programmes',
                          color: AppTheme.info,
                          path: '/coach/planning',
                        ),
                        _NavCard(
                          icon: Icons.event_busy,
                          label: 'Absences',
                          color: AppTheme.error,
                          path: '/coach/absences',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Course tile ───────────────────────────────────────────────────────────────
class _CourseTile extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final current = (course['currentParticipants'] ?? 0).toInt();
    final max     = (course['maxParticipants'] ?? 0).toInt();
    final pct     = max > 0 ? current / max : 0.0;
    final accentColor = pct >= 1.0 ? AppTheme.error : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Inner top highlight
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 44,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['name'] ?? 'Cours',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course['startTime'] ?? ''} – ${course['endTime'] ?? ''}  |  ${course['location'] ?? ''}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$current / $max',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'inscrits',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav card ──────────────────────────────────────────────────────────────────
class _NavCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
  });

  @override
  State<_NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<_NavCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: () => context.go(widget.path),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed && !disableAnimations) ? 0.96 : 1.0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF272727), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
