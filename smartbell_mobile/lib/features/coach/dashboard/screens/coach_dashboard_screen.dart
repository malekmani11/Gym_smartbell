import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';

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
  late final Animation<double>   _pulse;
  late final PageController      _pageCtrl;
  Timer? _carouselTimer;
  int _carouselPage = 0;

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
    _pageCtrl = PageController();
    _startCarousel();
    _load();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      _carouselPage = (_carouselPage + 1) % _slides.length;
      _pageCtrl.animateToPage(
        _carouselPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _carouselTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }
    final dio   = DioClient.instance.dio;
    final today = _days[DateTime.now().weekday - 1];

    try {
      // membres actifs : chargé via endpoint coach-specific
      _activeMembers = 0;

      try {
        final coachRes = await dio.get(
          ApiConstants.coachByUser(user.id),
          options: Options(extra: {'suppressLogoutOn401': true}),
        );
        final coachData = coachRes.data;
        final coachId   = coachData is Map ? ((coachData['id'] ?? 0) as num).toInt() : 0;
        if (coachId > 0) {
          final cRes = await dio.get(ApiConstants.courses,
              queryParameters: {'size': 100, 'active': true},
              options: Options(extra: {'suppressLogoutOn401': true}));
          final cData = cRes.data;
          final cList = cData is Map ? (cData['content'] ?? []) : (cData ?? []);
          final all   = List<Map<String, dynamic>>.from(cList);
          _todayCoursesList = all
              .where((c) => (c['dayOfWeek'] ?? '').toString().toUpperCase() == today)
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

  static const _slides = [
    _Slide(title: 'Mes membres',  subtitle: 'Gérer vos adhérents',     icon: Icons.people_outline,          path: '/coach/members',     imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80&fit=crop'),
    _Slide(title: 'Mon planning', subtitle: 'Vos cours de la semaine', icon: Icons.calendar_month_outlined, path: '/coach/planning',    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80&fit=crop'),
    _Slide(title: 'Validations',  subtitle: 'Programmes à examiner',   icon: Icons.verified_outlined,       path: '/coach/validations', imageUrl: 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800&q=80&fit=crop'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final now  = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _pulseCtrl.stop();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: RefreshIndicator(
        color: const Color(0xFFE5A01A),
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Dark header ──
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF1A1A1A),
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
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(now, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Disponible',
                              style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cloche notifications
                    GestureDetector(
                      onTap: () => context.go('/coach/notifications'),
                      child: Container(
                        width: 38, height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                    Stack(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2A2A2A),
                          border: Border.all(
                            color: const Color(0xFFE5A01A).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user?.initials ?? 'C',
                          style: const TextStyle(
                            color: Color(0xFFE5A01A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0, top: 0,
                        child: RepaintBoundary(
                          child: disableAnimations
                              ? Container(
                                  width: 11, height: 11,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (_, __) => Container(
                                    width: 11, height: 11,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(76, 175, 80, _pulse.value),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Carousel ──
                    RepaintBoundary(
                     child: SizedBox(
                      height: 112,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _slides.length,
                        onPageChanged: (p) => setState(() => _carouselPage = p),
                        itemBuilder: (_, i) {
                          final slide = _slides[i];
                          return GestureDetector(
                            onTap: () => context.go(slide.path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: NetworkImage(slide.imageUrl),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withValues(alpha: 0.60),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5A01A).withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4)),
                                    ),
                                    child: Icon(slide.icon, color: const Color(0xFFE5A01A), size: 26),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(slide.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(slide.subtitle, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                                    ],
                                  )),
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5A01A).withValues(alpha: 0.20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward_ios, color: Color(0xFFE5A01A), size: 12),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                    const SizedBox(height: 8),
                    // Carousel dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width:  _carouselPage == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _carouselPage == i ? const Color(0xFFE5A01A) : const Color(0xFFBBBBBB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                    const SizedBox(height: 20),

                    // ── Shortcuts ──
                    const Text('ACCÈS RAPIDE', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _ShortcutChip(icon: Icons.people_outline,          label: 'Membres',     path: '/coach/members'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.calendar_month_outlined, label: 'Planning',    path: '/coach/planning'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.verified_outlined,       label: 'Validations', path: '/coach/validations'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.event_busy_outlined,     label: 'Absences',    path: '/coach/absences'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.event_outlined,          label: 'Événements',  path: '/coach/events'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.report_outlined,         label: 'Plaintes',    path: '/coach/complaints'),
                        const SizedBox(width: 8),
                        _ShortcutChip(icon: Icons.star_outline,            label: 'Évaluations', path: '/coach/ratings'),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats ──
                    const Text('STATISTIQUES', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _StatCard(value: '$_activeMembers', label: 'Membres actifs',     icon: Icons.people_outline)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(value: '$_todayCourses',  label: "Cours aujourd'hui", icon: Icons.today)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(value: '$_monthHours h',  label: 'Heures ce mois',    icon: Icons.timer_outlined)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Courses today ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("COURS D'AUJOURD'HUI", style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                        GestureDetector(
                          onTap: () => context.go('/coach/planning'),
                          child: const Text('Planning →', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_todayCoursesList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        ),
                        child: const Center(
                          child: Text("Aucun cours aujourd'hui", style: TextStyle(color: Color(0xFF888888))),
                        ),
                      )
                    else
                      ..._todayCoursesList.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourseTile(course: c),
                      )),
                    const SizedBox(height: 20),

                    // ── Événements à venir ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ÉVÉNEMENTS À VENIR', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                        GestureDetector(
                          onTap: () => context.go('/coach/events'),
                          child: const Text('Voir tout →', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _UpcomingEventsBanner(onTap: () => context.go('/coach/events')),
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

// ── Slide data ─────────────────────────────────────────────────────────────────

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
  final String imageUrl;
  const _Slide({required this.title, required this.subtitle, required this.icon, required this.path, required this.imageUrl});
}

// ── Shortcut chip ──────────────────────────────────────────────────────────────

class _ShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  const _ShortcutChip({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go(path),
    child: Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE5A01A), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 9, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE5A01A), size: 18),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

// ── Course tile ────────────────────────────────────────────────────────────────

class _CourseTile extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final current = (course['currentParticipants'] ?? 0).toInt();
    final max     = (course['maxParticipants'] ?? 0).toInt();
    final isFull  = max > 0 && current >= max;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 4, height: 60,
          decoration: BoxDecoration(
            color: isFull ? const Color(0xFFE53935) : const Color(0xFFE5A01A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14), bottomLeft: Radius.circular(14),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['name'] ?? 'Cours', style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    '${course['startTime'] ?? ''} – ${course['endTime'] ?? ''}  ·  ${course['location'] ?? ''}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              )),
              Text(
                '$current/$max',
                style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Upcoming events banner ──────────────────────────────────────────────────────

class _UpcomingEventsBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _UpcomingEventsBanner({required this.onTap});
  @override
  State<_UpcomingEventsBanner> createState() => _UpcomingEventsBannerState();
}

class _UpcomingEventsBannerState extends State<_UpcomingEventsBanner> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res  = await DioClient.instance.dio.get(
        '/events',
        queryParameters: {'size': 3, 'sort': 'eventDate,asc'},
        options: Options(extra: {'suppressLogoutOn401': true}),
      );
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      final now  = DateTime.now();
      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(list).where((e) {
            final d = DateTime.tryParse(e['eventDate'] ?? '');
            return d != null && d.isAfter(now);
          }).take(3).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 70,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5)),
        child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))),
      );
    }

    if (_events.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5)),
          child: const Row(children: [
            Icon(Icons.event_outlined, color: Color(0xFFBBBBBB), size: 20),
            SizedBox(width: 10),
            Text('Aucun événement à venir', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
          ]),
        ),
      );
    }

    return Column(
      children: _events.map((e) {
        final title = e['title'] as String? ?? 'Événement';
        final dateStr = e['eventDate'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        final location = e['location'] as String? ?? '';
        final count = ((e['registrationCount'] ?? 0) as num).toInt();
        final max   = ((e['maxParticipants']   ?? 0) as num).toInt();

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A01A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event, color: Color(0xFFE5A01A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (date != null)
                  Text(
                    '${date.day}/${date.month} à ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}${location.isNotEmpty ? ' · $location' : ''}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
              ])),
              if (max > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: count >= max ? const Color(0xFFFCEBEB) : const Color(0xFFEAF3DE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count/$max',
                    style: TextStyle(
                      color: count >= max ? const Color(0xFFE53935) : const Color(0xFF3B6D11),
                      fontSize: 11, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 16),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
