import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/models/measurement.dart';
import '../../checkin/screens/checkin_scanner_screen.dart';

class AdherentHomeScreen extends StatefulWidget {
  const AdherentHomeScreen({super.key});

  @override
  State<AdherentHomeScreen> createState() => _AdherentHomeScreenState();
}

class _AdherentHomeScreenState extends State<AdherentHomeScreen>
    with TickerProviderStateMixin {
  int _checkinsThisMonth = 0;
  int _loyaltyPoints     = 0;
  int _daysRemaining     = 0;
  int _totalDays         = 30;
  String? _planName;
  String? _nextCourseName;
  String? _nextCourseTime;
  bool _loading = true;

  // Progress snapshot
  double? _currentWeight;
  double? _weightVariation;

  // Upcoming events
  List<Map<String, dynamic>> _upcomingEvents = [];

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // Carousel
  int _currentSlide = 0;
  late PageController _pageCtrl;
  Timer? _slideTimer;

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
    _slideTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => _currentSlide = (_currentSlide + 1) % 4);
      _pageCtrl.animateToPage(
        _currentSlide,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }
    final dio = DioClient.instance.dio;

    try {
      _loyaltyPoints = 0;
      _checkinsThisMonth = 0;

      // Load subscription
      try {
        final subRes = await dio.get(ApiConstants.subscriptionsByUser(user.id),
            queryParameters: {'size': 1, 'sort': 'createdAt,desc'});
        final subData = subRes.data;
        final subList = subData is Map ? (subData['content'] ?? []) : [];
        if ((subList as List).isNotEmpty) {
          final sub = subList.first;
          _planName = sub['planName'];
          if (sub['endDate'] != null) {
            final end = DateTime.tryParse(sub['endDate']);
            if (end != null) {
              _daysRemaining = end.difference(DateTime.now()).inDays.clamp(0, 999);
            }
          }
          if (sub['startDate'] != null && sub['endDate'] != null) {
            final start = DateTime.tryParse(sub['startDate']);
            final end   = DateTime.tryParse(sub['endDate']);
            if (start != null && end != null) {
              _totalDays = end.difference(start).inDays.clamp(1, 999);
            }
          }
        }
      } catch (_) {}

      // Load progress snapshot from local cache (same key as ProgressService)
      try {
        final membRes = await dio.get(ApiConstants.memberByUser(user.id));
        final mid = (membRes.data['id'] ?? user.id).toInt();
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('smartbell_measurements_$mid');
        if (raw != null) {
          final list = (jsonDecode(raw) as List)
              .map((j) => Measurement.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          if (list.isNotEmpty) {
            _currentWeight  = list.last.weight;
            _weightVariation = list.length > 1
                ? list.last.weight - list.first.weight
                : null;
          }
        }
      } catch (_) {}

      // Load upcoming events
      try {
        final evRes = await dio.get('/events',
            queryParameters: {'size': 5, 'sort': 'eventDate,asc'});
        final evData = evRes.data;
        final list = evData is Map ? (evData['content'] ?? []) : (evData ?? []);
        final now = DateTime.now();
        _upcomingEvents = List<Map<String, dynamic>>.from(list)
            .where((e) {
              final d = DateTime.tryParse(e['eventDate'] ?? '');
              final count = (e['registrationCount'] ?? 0) as int;
              final max   = (e['maxParticipants']  ?? 0) as int;
              return d != null && d.isAfter(now) && (max == 0 || count < max);
            })
            .take(4)
            .toList();
      } catch (_) {}

      // Load next course today
      try {
        final courseRes = await dio.get(ApiConstants.courses,
            queryParameters: {'size': 50, 'active': true});
        final courseData = courseRes.data;
        final courseList = courseData is Map
            ? (courseData['content'] ?? [])
            : (courseData ?? []);
        final days = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
        final today = days[DateTime.now().weekday - 1];
        final todayCourses = (courseList as List)
            .where((c) => (c['dayOfWeek'] ?? '').toString().toUpperCase() == today)
            .toList();
        if (todayCourses.isNotEmpty) {
          _nextCourseName = todayCourses.first['name'];
          _nextCourseTime = todayCourses.first['startTime'];
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _loading = false);
    } on DioException {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  double get _subscriptionProgress =>
      _totalDays > 0 ? (_daysRemaining / _totalDays).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initiales = user?.initials ?? 'M';
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) _pulseCtrl.stop();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: RefreshIndicator(
        color: const Color(0xFFE5A01A),
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Sliver 1 — Header sombre ──
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF1A1A1A),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20, right: 20, bottom: 14,
                ),
                child: Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A01A),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.black, size: 15),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SmartBell',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Stack(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE5A01A)),
                      alignment: Alignment.center,
                      child: Text(
                        initiales,
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 11, height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CBA7D),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5A01A)),
                ),
              )
            else ...[

            // ── Sliver 2 — Carousel hero ──
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF1A1A1A),
                height: 210,
                child: Column(children: [
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _currentSlide = i),
                      itemCount: 4,
                      itemBuilder: (_, i) => _buildSlide(i),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final active = i == _currentSlide;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentSlide = i);
                          _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFE5A01A) : const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                ]),
              ),
            ),

            // ── Sliver 3 — Raccourcis horizontaux ──
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFF5F5F0),
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: 11,
                  itemBuilder: (_, i) {
                    // '__scanner__' = Navigator.push vers CheckinScannerScreen
                    const chips = [
                      ('Entraînement', Icons.fitness_center,           '/member/training',        false),
                      ('Nutrition',    Icons.restaurant_menu,          '/member/nutrition',       false),
                      ('Cours',        Icons.calendar_today,           '/member/courses',         false),
                      ('Événements',   Icons.celebration_outlined,     '/member/events',          false),
                      ('Messages',     Icons.chat_outlined,            '/member/chat',            false),
                      ('Fidélité',     Icons.stars,                    '/member/loyalty',         false),
                      ('Plaintes',     Icons.forum_outlined,           '/member/complaints',      false),
                      ('Profil',       Icons.person_outline,           '/member/profile',         false),
                      ('Scanner',      Icons.qr_code_scanner,          '__scanner__',             false),
                      ('Mes visites',  Icons.history,                  '/member/checkin-history', false),
                      ('Progression',  Icons.monitor_weight_outlined,  '/member/progress',        false),
                    ];
                    final (label, icon, route, _) = chips[i];
                    return GestureDetector(
                      onTap: () {
                        if (route == '__scanner__') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinScannerScreen()));
                        } else {
                          context.go(route);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 15, color: const Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 4),
                          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Sliver 4 — Grille stats 2 colonnes ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 118,
                ),
                delegate: SliverChildListDelegate([
                  // Carte 1 — Visites
                  _StatCard(
                    icon: Icons.bar_chart,
                    iconBg: const Color(0xFFFAEEDA),
                    iconColor: const Color(0xFFBA7517),
                    value: '$_checkinsThisMonth',
                    valueColor: const Color(0xFFBA7517),
                    label: 'Visites',
                    sub: 'Ce mois',
                    subColor: const Color(0xFF888888),
                  ),
                  // Carte 2 — Points
                  _StatCard(
                    icon: Icons.stars,
                    iconBg: const Color(0xFFEAF3DE),
                    iconColor: const Color(0xFF3B6D11),
                    value: '$_loyaltyPoints',
                    valueColor: const Color(0xFF3B6D11),
                    label: 'Points',
                    sub: 'Fidélité',
                    subColor: const Color(0xFF3B6D11),
                  ),
                  // Carte 3 — Jours
                  _StatCard(
                    icon: Icons.timer_outlined,
                    iconBg: _daysRemaining < 7 ? const Color(0xFFFCEBEB) : const Color(0xFFE6F1FB),
                    iconColor: _daysRemaining < 7 ? const Color(0xFFA32D2D) : const Color(0xFF185FA5),
                    value: '$_daysRemaining',
                    valueColor: _daysRemaining < 7 ? const Color(0xFFA32D2D) : const Color(0xFF185FA5),
                    label: 'Jours',
                    sub: 'Restants',
                    subColor: _daysRemaining < 7 ? const Color(0xFFA32D2D) : const Color(0xFF185FA5),
                  ),
                  // Carte 4 — Poids
                  _StatCard(
                    icon: Icons.show_chart,
                    iconBg: const Color(0xFFEEEDFE),
                    iconColor: const Color(0xFF534AB7),
                    value: _currentWeight != null ? '${_currentWeight!.toStringAsFixed(1)}kg' : '—',
                    valueColor: const Color(0xFF534AB7),
                    label: 'Poids',
                    sub: _weightVariation != null
                        ? '${_weightVariation! > 0 ? '+' : ''}${_weightVariation!.toStringAsFixed(1)}kg'
                        : 'Suivi',
                    subColor: const Color(0xFF888888),
                  ),
                ]),
              ),
            ),

            // ── Sliver 5 — Carte abonnement ──
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        _planName ?? 'Abonnement',
                        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _daysRemaining < 7 ? const Color(0xFFFCEBEB) : const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_daysRemaining jours',
                        style: TextStyle(
                          color: _daysRemaining < 7 ? const Color(0xFFA32D2D) : const Color(0xFF3B6D11),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _subscriptionProgress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE8E8E8),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFE5A01A)),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Sliver 6 — Carte progression ──
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => context.go('/member/progress'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.show_chart, color: Color(0xFFBA7517), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text(
                          'Ma Progression',
                          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (_currentWeight != null)
                          Text(
                            '${_currentWeight!.toStringAsFixed(1)} kg${_weightVariation != null ? ' (${_weightVariation! > 0 ? "+" : ""}${_weightVariation!.toStringAsFixed(1)} kg)' : ''}',
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                          ),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18),
                  ]),
                ),
              ),
            ),

            // ── Sliver 7 — Section "Aujourd'hui" ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text(
                      "Aujourd'hui",
                      style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/member/courses'),
                      child: const Text('Voir tout', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(children: [
                      _TodayRow(
                        icon: Icons.fitness_center,
                        iconBg: const Color(0xFFFAEEDA),
                        iconColor: const Color(0xFFBA7517),
                        title: 'Séance',
                        sub: "Démarrer l'entraînement",
                        onTap: () => context.go('/member/training'),
                      ),
                      const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF5F5F0), indent: 16, endIndent: 16),
                      _TodayRow(
                        icon: Icons.restaurant_menu,
                        iconBg: const Color(0xFFEAF3DE),
                        iconColor: const Color(0xFF3B6D11),
                        title: 'Nutrition',
                        sub: 'Voir mon plan',
                        onTap: () => context.go('/member/nutrition'),
                      ),
                      const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF5F5F0), indent: 16, endIndent: 16),
                      _TodayRow(
                        icon: Icons.event,
                        iconBg: const Color(0xFFE6F1FB),
                        iconColor: const Color(0xFF185FA5),
                        title: _nextCourseName ?? 'Cours',
                        sub: _nextCourseTime != null ? 'À $_nextCourseTime' : 'Voir le planning',
                        onTap: () => context.go('/member/courses'),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),

            // ── Sliver 8 — Événements à venir ──
            if (_upcomingEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text(
                        'Événements à venir',
                        style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/member/events'),
                        child: const Text('Voir tout', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _upcomingEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _buildEventChip(_upcomingEvents[i]),
                      ),
                    ),
                  ]),
                ),
              ),

            ], // end else
          ],
        ),
      ),
    );
  }

  Widget _buildEventChip(Map<String, dynamic> event) {
    final title    = event['title'] as String? ?? 'Événement';
    final dateStr  = event['eventDate'] as String? ?? '';
    final location = event['location'] as String? ?? '';
    final count    = (event['registrationCount'] ?? 0) as int;
    final max      = (event['maxParticipants']  ?? 0) as int;
    final date     = DateTime.tryParse(dateStr);
    final fillPct  = max > 0 ? (count / max).clamp(0.0, 1.0) : 0.0;

    final months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    final dayStr  = date != null ? date.day.toString().padLeft(2, '0') : '--';
    final monStr  = date != null ? months[date.month - 1] : '---';
    final timeStr = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: () => context.go('/member/events'),
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Date badge + icône
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Text(dayStr, style: const TextStyle(color: Color(0xFFBA7517), fontSize: 16, fontWeight: FontWeight.w800, height: 1.0)),
                Text(monStr, style: const TextStyle(color: Color(0xFFBA7517), fontSize: 9,  fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            const Icon(Icons.celebration_outlined, color: Color(0xFFE5A01A), size: 18),
          ]),
          const SizedBox(height: 8),
          // Titre
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 4),
          // Heure + lieu
          if (timeStr.isNotEmpty)
            Row(children: [
              const Icon(Icons.access_time, size: 10, color: Color(0xFF888888)),
              const SizedBox(width: 3),
              Text(timeStr, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
            ]),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF888888)),
              const SizedBox(width: 3),
              Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 10))),
            ]),
          ],
          const Spacer(),
          // Barre remplissage
          if (max > 0) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$count/$max places', style: const TextStyle(color: Color(0xFF888888), fontSize: 9)),
              Text('${(fillPct * 100).toInt()}%',
                  style: TextStyle(
                    color: fillPct >= 0.8 ? const Color(0xFFE5A01A) : const Color(0xFF3B6D11),
                    fontSize: 9, fontWeight: FontWeight.w700,
                  )),
            ]),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fillPct,
                minHeight: 3,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation(
                  fillPct >= 0.8 ? const Color(0xFFE5A01A) : const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSlide(int index) {
    final slides = [
      _SlideData(
        tag: 'VISITES', color: const Color(0xFFE5A01A), icon: Icons.bar_chart,
        title: '$_checkinsThisMonth visites ce mois', sub: 'Continuez vos efforts !',
        btnLabel: 'Voir progression', route: '/member/progress',
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80&fit=crop',
      ),
      _SlideData(
        tag: 'ABONNEMENT', color: const Color(0xFFE5A01A), icon: Icons.card_membership,
        title: '$_daysRemaining jours restants', sub: _planName ?? 'Plan actif',
        titleColor: _daysRemaining < 7 ? const Color(0xFFA32D2D) : Colors.white,
        btnLabel: 'Mon abonnement', route: '/member/subscription',
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80&fit=crop',
      ),
      _SlideData(
        tag: 'COURS', color: const Color(0xFF9F97EC), icon: Icons.event,
        title: _nextCourseName ?? "Aucun cours aujourd'hui",
        sub: _nextCourseTime != null ? 'À $_nextCourseTime' : 'Voir le planning',
        btnLabel: 'Voir cours', route: '/member/courses',
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80&fit=crop',
      ),
      _SlideData(
        tag: 'FIDÉLITÉ', color: const Color(0xFF4CBA7D), icon: Icons.stars,
        title: '$_loyaltyPoints points', sub: 'Programme fidélité SmartBell',
        btnLabel: 'Mes points', route: '/member/loyalty',
        imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80&fit=crop',
      ),
    ];
    final s = slides[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: NetworkImage(s.imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.58),
                BlendMode.darken,
              ),
            ),
          ),
          child: Stack(children: [
            // Gradient latéral pour lisibilité du texte
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: s.color.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Text(s.tag, style: TextStyle(color: s.color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Text(s.title, style: TextStyle(color: s.titleColor ?? Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s.sub, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.go(s.route),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(s.btnLabel, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Today row ─────────────────────────────────────────────────────────────────
class _TodayRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, sub;
  final VoidCallback onTap;

  const _TodayRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w500)),
            Text(sub, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 16),
      ]),
    ),
  );
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor, valueColor, subColor;
  final String value, label, sub;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.sub,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: iconColor, size: 14),
      ),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w700, height: 1.1)),
      const SizedBox(height: 1),
      Text(label, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 11)),
      Text(sub,   style: TextStyle(color: subColor, fontSize: 10)),
    ]),
  );
}

// ── Slide data ────────────────────────────────────────────────────────────────
class _SlideData {
  final String tag, title, sub, btnLabel, route, imageUrl;
  final IconData icon;
  final Color color;
  final Color? titleColor;
  const _SlideData({
    required this.tag,
    required this.color,
    required this.icon,
    required this.title,
    required this.sub,
    required this.btnLabel,
    required this.route,
    required this.imageUrl,
    this.titleColor,
  });
}
