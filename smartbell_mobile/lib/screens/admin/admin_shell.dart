import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../models/statistics_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/adherent/courses/models/course.dart';
import '../../features/shared/notifications/notifications_screen.dart';

// ─── Shell ───────────────────────────────────────────────────────────────────

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _navItems = [
    _TabItem(label: 'Dashboard', icon: Icons.home_outlined, activeIcon: Icons.home, path: '/admin'),
    _TabItem(label: 'Membres', icon: Icons.people_outline, activeIcon: Icons.people, path: '/admin/members'),
    _TabItem(label: 'Paiements', icon: Icons.payment_outlined, activeIcon: Icons.payment, path: '/admin/payments'),
    _TabItem(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person, path: '/admin/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navItems.indexWhere((t) => t.path == location).clamp(0, _navItems.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                // Index 0 — Dashboard
                _buildTab(context, _navItems[0], currentIndex == 0, 0),
                // Index 1 — Membres
                _buildTab(context, _navItems[1], currentIndex == 1, 1),
                // Index 2 — Bouton central scan
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/admin/qr-display'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52, height: 52,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Color(0xFFE5A01A), size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                // Index 3 — Paiements
                _buildTab(context, _navItems[2], currentIndex == 2, 2),
                // Index 4 — Profil
                _buildTab(context, _navItems[3], currentIndex == 3, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, _TabItem tab, bool selected, int idx) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(tab.path),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.activeIcon : tab.icon,
              color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: TextStyle(
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _TabItem({required this.label, required this.icon, required this.activeIcon, required this.path});
}

// ─── Dashboard Page ───────────────────────────────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  StatisticsModel? _stats;
  bool _loading = true;
  String? _error;
  int _carouselIndex = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _loadStats();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.get('/statistics');
      setState(() {
        _stats = StatisticsModel.fromJson(res.data as Map<String, dynamic>);
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: RefreshIndicator(
        color: const Color(0xFFE5A01A),
        backgroundColor: Colors.white,
        onRefresh: _loadStats,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
            : _error != null
                ? _buildError()
                : _buildContent(user?.fullName ?? 'Admin'),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888))),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _loadStats,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
          child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE5A01A), fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );

  Widget _buildContent(String name) {
    final s = _stats!;
    final slides = [
      _SlideData(tag: 'Revenus', title: '${s.revenueThisMonth.toStringAsFixed(0)} DT ce mois', sub: '+12% vs mois précédent', icon: Icons.bar_chart, color: const Color(0xFFE5A01A), route: '/admin/payments', btn: 'Voir paiements', imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80&fit=crop'),
      _SlideData(tag: 'Membres', title: '${s.activeMembers} membres actifs', sub: '${s.totalMembers - s.activeMembers} inactifs à relancer', icon: Icons.people, color: const Color(0xFFE5A01A), route: '/admin/members', btn: 'Voir membres', imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80&fit=crop'),
      _SlideData(tag: 'Check-in', title: 'Scanner rapide membres', sub: 'Enregistrez les entrées QR', icon: Icons.door_front_door_outlined, color: const Color(0xFF4CBA7D), route: '', btn: 'Scanner', imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800&q=80&fit=crop'),
      _SlideData(tag: 'Coachs', title: '${s.totalCoaches} coachs', sub: '${s.totalCourses} cours actifs cette semaine', icon: Icons.school, color: const Color(0xFF9F97EC), route: '/admin/coaches', btn: 'Voir coachs', imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80&fit=crop'),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Top bar ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFF1A1A1A),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16, bottom: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: const Color(0xFFE5A01A), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.fitness_center, color: Colors.black, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('SmartBell', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Stack(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A01A),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (mounted) context.go('/login');
                  },
                  child: Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
                    child: const Icon(Icons.logout, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Carousel ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFF1A1A1A),
            height: 212,
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _carouselIndex = i),
                    itemBuilder: (_, i) {
                      final slide = slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              image: DecorationImage(
                                image: NetworkImage(slide.imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.55),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Gradient left overlay for text readability
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: slide.color.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: slide.color.withValues(alpha: 0.5), width: 0.5),
                                        ),
                                        child: Text(slide.tag, style: TextStyle(color: slide.color, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        slide.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(slide.sub, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                                      const SizedBox(height: 14),
                                      GestureDetector(
                                        onTap: slide.route.isNotEmpty ? () => context.go(slide.route) : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(color: slide.color, borderRadius: BorderRadius.circular(10)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(slide.btn, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _carouselIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFE5A01A) : const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Shortcuts horizontaux ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFFF5F5F0),
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Shortcut(label: 'Membres', icon: Icons.people_outline, route: '/admin/members'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Coachs', icon: Icons.school_outlined, route: '/admin/coaches'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Paiements', icon: Icons.payment_outlined, route: '/admin/payments'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Rapports', icon: Icons.bar_chart_outlined, route: '/admin/reports'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Messages', icon: Icons.chat_bubble_outline, route: '/admin/messages'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Planning', icon: Icons.calendar_today_outlined, route: '/admin/courses'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Plaintes', icon: Icons.report_problem_outlined, route: '/admin/complaints'),
                  const SizedBox(width: 10),
                  _Shortcut(label: 'Absences', icon: Icons.event_busy_outlined, route: '/admin/absences'),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),

        // ── Stats 2x2 ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: _StatCard(icon: Icons.people_outline, value: '${s.totalMembers}', label: 'Membres', sub: '${s.activeMembers} actifs', route: '/admin/members')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(icon: Icons.school_outlined, value: '${s.totalCoaches}', label: 'Coachs', sub: '${s.totalCourses} cours', route: '/admin/coaches')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _StatCard(icon: Icons.card_membership_outlined, value: '${s.activeSubscriptions}', label: 'Abonnements', sub: 'Tous actifs', route: '')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(icon: Icons.login_outlined, value: '${s.totalCheckInsToday}', label: 'Check-ins', sub: "Aujourd'hui", route: '')),
              ]),
            ]),
          ),
        ),

        // ── Carte revenus ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Revenus annuels', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                      Text('${s.revenueThisYear.toStringAsFixed(2)} DT',
                          style: const TextStyle(color: Color(0xFFE5A01A), fontSize: 24, fontWeight: FontWeight.w600)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Ce mois', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                      Text('${s.revenueThisMonth.toStringAsFixed(0)} DT',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const Text('↑ +12%', style: TextStyle(color: Color(0xFF4CBA7D), fontSize: 11)),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _buildBarChart(),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jan', style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                    Text('Mai', style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                    Text('Déc', style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Carte check-in rapide ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Accès rapide', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    Text('QR code entrée salle', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w500)),
                    Text('Affichez-le à l\'entrée pour les membres', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 10)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/admin/qr-display'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(11)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, color: Color(0xFFE5A01A), size: 16),
                        SizedBox(width: 6),
                        Text('Afficher QR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBarChart() {
    const data = [40.0, 55, 48, 70, 52, 80, 62, 88, 68, 75, 100, 60];
    const maxVal = 100.0;
    const heightMax = 32.0;
    return List.generate(data.length, (i) {
      final isHighlighted = i >= 10;
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          height: (data[i] / maxVal) * heightMax,
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFFE5A01A) : const Color(0xFF2A2A2A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
        ),
      );
    });
  }
}

class _SlideData {
  final String tag, title, sub, route, btn, imageUrl;
  final IconData icon;
  final Color color;
  const _SlideData({required this.tag, required this.title, required this.sub, required this.icon, required this.color, required this.route, required this.btn, required this.imageUrl});
}

class _Shortcut extends StatelessWidget {
  final String label, route;
  final IconData icon;
  const _Shortcut({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route.isNotEmpty ? () => context.go(route) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F0), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label, sub, route;

  const _StatCard({
    required this.icon,
    required this.value, required this.label, required this.sub,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route.isNotEmpty ? () => context.go(route) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Row(
          children: [
            // Icône
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE5A01A).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFE5A01A), size: 20),
            ),
            const SizedBox(width: 12),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(label,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                  const SizedBox(height: 1),
                  Text(sub,
                    style: const TextStyle(
                      color: Color(0xFFE5A01A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Flèche si cliquable
            if (route.isNotEmpty)
              const Icon(Icons.chevron_right, color: Color(0xFF3A3A3A), size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Courses Page ─────────────────────────────────────────────────────────────

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _dio = ApiClient().dio;
  List<Course> _courses = [];
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;
  String? _error;
  final Set<int> _toggling = {};

  static const _dayColors = {
    'MONDAY':    Color(0xFFE57373),
    'TUESDAY':   Color(0xFF81C784),
    'WEDNESDAY': Color(0xFF64B5F6),
    'THURSDAY':  Color(0xFFFFB74D),
    'FRIDAY':    Color(0xFFBA68C8),
    'SATURDAY':  Color(0xFF4DB6AC),
    'SUNDAY':    Color(0xFFF06292),
  };

  static const _dayLabels = {
    'MONDAY': 'Lun', 'TUESDAY': 'Mar', 'WEDNESDAY': 'Mer',
    'THURSDAY': 'Jeu', 'FRIDAY': 'Ven', 'SATURDAY': 'Sam', 'SUNDAY': 'Dim',
  };

  static const _dayOptions = [
    {'key': 'MONDAY',    'label': 'Lundi'},
    {'key': 'TUESDAY',   'label': 'Mardi'},
    {'key': 'WEDNESDAY', 'label': 'Mercredi'},
    {'key': 'THURSDAY',  'label': 'Jeudi'},
    {'key': 'FRIDAY',    'label': 'Vendredi'},
    {'key': 'SATURDAY',  'label': 'Samedi'},
    {'key': 'SUNDAY',    'label': 'Dimanche'},
  ];

  @override
  void initState() { super.initState(); _load(); _loadCoaches(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get('/courses', queryParameters: {'size': 100, 'all': 'true'});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      const dayOrder = {
        'MONDAY': 0, 'TUESDAY': 1, 'WEDNESDAY': 2, 'THURSDAY': 3,
        'FRIDAY': 4, 'SATURDAY': 5, 'SUNDAY': 6,
      };
      final courses = (list as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          final dayA = dayOrder[a.dayOfWeek?.toUpperCase()] ?? 7;
          final dayB = dayOrder[b.dayOfWeek?.toUpperCase()] ?? 7;
          if (dayA != dayB) return dayA.compareTo(dayB);
          return (a.startTime ?? '').compareTo(b.startTime ?? '');
        });
      setState(() {
        _courses = courses;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = e.response?.data?['message'] ?? 'Erreur de chargement'; _loading = false; });
    }
  }

  Future<void> _loadCoaches() async {
    try {
      final res = await _dio.get('/coaches', queryParameters: {'size': 100});
      final data = res.data;
      final list = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _coaches = List<Map<String, dynamic>>.from(list as List);
      });
    } catch (_) {}
  }

  Future<void> _toggleActive(Course course) async {
    setState(() => _toggling.add(course.id));
    try {
      await _dio.put('/courses/${course.id}', data: {
        'name':            course.name,
        'dayOfWeek':       course.dayOfWeek,
        'startTime':       course.startTime,
        'endTime':         course.endTime,
        'maxParticipants': course.maxParticipants,
        'coachId':         course.coachId,
        'active':          !course.active,
      });
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['message'] ?? 'Erreur'),
          backgroundColor: const Color(0xFFA32D2D),
        ));
      }
    } finally {
      if (mounted) setState(() => _toggling.remove(course.id));
    }
  }

  Future<void> _saveCourse(Map<String, dynamic> payload, int? id) async {
    try {
      if (id == null) {
        await _dio.post('/courses', data: payload);
      } else {
        await _dio.put('/courses/$id', data: payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(id == null ? 'Cours créé avec succès' : 'Cours modifié avec succès'),
          backgroundColor: const Color(0xFF4CBA7D),
        ));
      }
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['message'] ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: const Color(0xFFA32D2D),
        ));
      }
    }
  }

  Future<void> _deleteCourse(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le cours', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Supprimer "$name" ? Cette action est irréversible.',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFA32D2D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _dio.delete('/courses/$id');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cours supprimé'),
          backgroundColor: Color(0xFF4CBA7D),
        ));
      }
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['message'] ?? 'Impossible de supprimer'),
          backgroundColor: const Color(0xFFA32D2D),
        ));
      }
    }
  }

  void _openModal({Course? course}) {
    final nameCtrl     = TextEditingController(text: course?.name ?? '');
    final capacityCtrl = TextEditingController(text: '${course?.maxParticipants ?? 15}');
    String selectedDay   = course?.dayOfWeek ?? 'MONDAY';
    String startTime     = course?.startTime ?? '08:00';
    String endTime       = course?.endTime   ?? '09:00';
    int?   selectedCoach = course?.coachId;
    bool   isActive      = course?.active ?? true;
    bool   saving        = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFF444444), borderRadius: BorderRadius.circular(2)),
                )),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course == null ? 'Nouveau cours' : 'Modifier le cours',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    if (course != null)
                      GestureDetector(
                        onTap: () => _deleteCourse(course.id, course.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA32D2D).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA32D2D).withValues(alpha: 0.3)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.delete_outline, color: Color(0xFFA32D2D), size: 14),
                            SizedBox(width: 4),
                            Text('Supprimer', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nom
                _modalLabel('Nom du cours'),
                _modalField(controller: nameCtrl, hint: 'Ex: Yoga Matinal', maxLength: 50),
                const SizedBox(height: 14),

                // Jour
                _modalLabel('Jour de la semaine'),
                _ModalDropdown<String>(
                  value: selectedDay,
                  items: _dayOptions.map((d) => DropdownMenuItem(
                    value: d['key']!,
                    child: Text(d['label']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setModal(() => selectedDay = v!),
                ),
                const SizedBox(height: 14),

                // Horaires
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _modalLabel('Heure début'),
                    _TimePickerField(
                      value: startTime,
                      onChanged: (v) => setModal(() => startTime = v),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _modalLabel('Heure fin'),
                    _TimePickerField(
                      value: endTime,
                      onChanged: (v) => setModal(() => endTime = v),
                    ),
                  ])),
                ]),
                const SizedBox(height: 14),

                // Capacité
                _modalLabel('Capacité max'),
                _modalField(controller: capacityCtrl, hint: '20', keyboardType: TextInputType.number),
                const SizedBox(height: 14),

                // Coach
                _modalLabel('Coach'),
                _ModalDropdown<int?>(
                  value: selectedCoach,
                  hint: 'Sélectionner un coach',
                  items: _coaches.map((c) {
                    final id   = (c['id'] as num).toInt();
                    final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (v) => setModal(() => selectedCoach = v),
                ),
                const SizedBox(height: 14),

                // Statut actif / inactif
                GestureDetector(
                  onTap: () => setModal(() => isActive = !isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4CBA7D).withValues(alpha: 0.10)
                          : const Color(0xFFA32D2D).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF4CBA7D).withValues(alpha: 0.4)
                            : const Color(0xFFA32D2D).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                          color: isActive ? const Color(0xFF4CBA7D) : const Color(0xFFA32D2D),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isActive ? 'Cours actif' : 'Cours inactif',
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF4CBA7D) : const Color(0xFFA32D2D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isActive ? 'Appuyer pour désactiver' : 'Appuyer pour activer',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setModal(() => isActive = v),
                          activeColor: const Color(0xFF4CBA7D),
                          inactiveThumbColor: const Color(0xFFA32D2D),
                          inactiveTrackColor: const Color(0xFFA32D2D).withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                        ),
                        child: const Center(child: Text('Annuler', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: saving ? null : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        if (selectedCoach == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Veuillez sélectionner un coach'),
                            backgroundColor: Color(0xFFA32D2D),
                          ));
                          return;
                        }
                        setModal(() => saving = true);
                        Navigator.pop(ctx);
                        await _saveCourse({
                          'name':            nameCtrl.text.trim(),
                          'dayOfWeek':       selectedDay,
                          'startTime':       startTime,
                          'endTime':         endTime,
                          'maxParticipants': int.tryParse(capacityCtrl.text) ?? 15,
                          'coachId':         selectedCoach,
                          'active':          isActive,
                        }, course?.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: saving ? const Color(0xFF444444) : const Color(0xFFE5A01A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              course == null ? 'Créer' : 'Sauvegarder',
                              style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active   = _courses.where((c) => c.active).length;
    final inactive = _courses.length - active;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF2A2A2A)),
        ),
        title: const Text('Cours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openModal(),
        backgroundColor: const Color(0xFFE5A01A),
        foregroundColor: const Color(0xFF1A1A1A),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A01A)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFE5A01A),
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Expanded(child: _SummaryTile(label: 'Total', value: '${_courses.length}', color: const Color(0xFFE5A01A), icon: Icons.fitness_center)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryTile(label: 'Actifs', value: '$active', color: const Color(0xFF4CBA7D), icon: Icons.check_circle_outline)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryTile(label: 'Inactifs', value: '$inactive', color: const Color(0xFF888888), icon: Icons.pause_circle_outline)),
                          ]),
                        ),
                      ),
                      if (_courses.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: Text('Aucun cours', style: TextStyle(color: Color(0xFF888888), fontSize: 15))),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _CourseRow(
                                course: _courses[i],
                                accent: _dayColors[_courses[i].dayOfWeek?.toUpperCase()] ?? const Color(0xFFE5A01A),
                                dayLabel: _dayLabels[_courses[i].dayOfWeek?.toUpperCase()] ?? '',
                                isToggling: _toggling.contains(_courses[i].id),
                                onToggle: () => _toggleActive(_courses[i]),
                                onTap: () => _openModal(course: _courses[i]),
                              ),
                              childCount: _courses.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFA32D2D), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Color(0xFF888888)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A01A), foregroundColor: Colors.black),
        child: const Text('Réessayer'),
      ),
    ]),
  );
}

// ── Modal helpers ──────────────────────────────────────────────────────────────

Widget _modalLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
);

Widget _modalField({
  required TextEditingController controller,
  String hint = '',
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
}) =>
  TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: 1,
    maxLength: maxLength,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5A01A), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      counterStyle: const TextStyle(color: Color(0xFF555555), fontSize: 10),
    ),
  );

class _ModalDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  const _ModalDropdown({required this.value, required this.items, required this.onChanged, this.hint = ''});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(10),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: Color(0xFF555555), fontSize: 13)),
        items: items,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF2A2A2A),
        isExpanded: true,
        iconEnabledColor: const Color(0xFF888888),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    ),
  );
}

class _TimePickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TimePickerField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final parts = value.split(':');
      final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
      final picked = await showTimePicker(context: context, initialTime: initial,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFFE5A01A), surface: Color(0xFF2A2A2A)),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        onChanged('${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}');
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.schedule, color: Color(0xFFE5A01A), size: 16),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF3A3A3A), width: 0.5),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
    ]),
  );
}

class _CourseRow extends StatelessWidget {
  final Course course;
  final Color accent;
  final String dayLabel;
  final bool isToggling;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  const _CourseRow({required this.course, required this.accent, required this.dayLabel, required this.isToggling, required this.onToggle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fillPct = course.maxParticipants > 0
        ? ((course.currentParticipants ?? 0) / course.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 90,
            decoration: BoxDecoration(
              color: course.active ? accent : const Color(0xFF555555),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(course.name,
                          style: TextStyle(
                            color: course.active ? Colors.white : const Color(0xFF888888),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (dayLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: course.active ? 0.15 : 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(dayLabel,
                            style: TextStyle(color: course.active ? accent : const Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (course.coachName != null) ...[
                      const Icon(Icons.person_outline, size: 12, color: Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Text(course.coachName!, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                      const SizedBox(width: 8),
                    ],
                    if (course.startTime != null) ...[
                      const Icon(Icons.schedule, size: 12, color: Color(0xFF666666)),
                      const SizedBox(width: 3),
                      Text(course.timeRange, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          '${course.currentParticipants ?? 0} / ${course.maxParticipants} participants',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fillPct,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF3A3A3A),
                            valueColor: AlwaysStoppedAnimation(
                              fillPct >= 1.0 ? const Color(0xFFA32D2D) : (fillPct >= 0.8 ? const Color(0xFFE5A01A) : const Color(0xFF4CBA7D)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    isToggling
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : GestureDetector(
                            onTap: onToggle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: course.active
                                    ? const Color(0xFFA32D2D).withValues(alpha: 0.12)
                                    : const Color(0xFF4CBA7D).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: course.active
                                      ? const Color(0xFFA32D2D).withValues(alpha: 0.4)
                                      : const Color(0xFF4CBA7D).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                course.active ? 'Désactiver' : 'Activer',
                                style: TextStyle(
                                  color: course.active ? const Color(0xFFA32D2D) : const Color(0xFF4CBA7D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    )); // Container + GestureDetector
  }
}

// ─── Profile Page ─────────────────────────────────────────────────────────────

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});
  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _dio = ApiClient().dio;

  // ── Modifier le profil ──────────────────────────────────────────────────────
  void _showEditProfileSheet() {
    final user = context.read<AuthProvider>().user;
    final firstCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastCtrl  = TextEditingController(text: user?.lastName  ?? '');
    final phoneCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)),
                )),
                const Text('Modifier le profil', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _profileField(controller: firstCtrl, label: 'Prénom', icon: Icons.person_outline),
                const SizedBox(height: 12),
                _profileField(controller: lastCtrl,  label: 'Nom',    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _profileField(controller: phoneCtrl, label: 'Téléphone', icon: Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setModal(() => saving = true);
                      try {
                        await _dio.put('/users/${user?.id}', data: {
                          'firstName': firstCtrl.text.trim(),
                          'lastName':  lastCtrl.text.trim(),
                          if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil mis à jour'), backgroundColor: Color(0xFF4CBA7D)),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: const Color(0xFFA32D2D)),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setModal(() => saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFE5A01A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Changer le mot de passe ─────────────────────────────────────────────────
  void _showChangePasswordSheet() {
    final user = context.read<AuthProvider>().user;
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool showCurrent = false;
    bool showNew     = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(2)),
                )),
                const Text('Changer le mot de passe', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _passwordField(
                  ctrl: currentCtrl, label: 'Mot de passe actuel',
                  show: showCurrent, onToggle: () => setModal(() => showCurrent = !showCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  ctrl: newCtrl, label: 'Nouveau mot de passe',
                  show: showNew, onToggle: () => setModal(() => showNew = !showNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  ctrl: confirmCtrl, label: 'Confirmer le mot de passe',
                  show: showConfirm, onToggle: () => setModal(() => showConfirm = !showConfirm),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Color(0xFFA32D2D)),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères'), backgroundColor: Color(0xFFA32D2D)),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Color(0xFFA32D2D)),
                        );
                        return;
                      }
                      setModal(() => saving = true);
                      try {
                        await _dio.patch('/users/${user?.id}/password', data: {
                          'currentPassword': currentCtrl.text,
                          'newPassword':     newCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mot de passe modifié avec succès'), backgroundColor: Color(0xFF4CBA7D)),
                          );
                        }
                      } on DioException catch (e) {
                        if (mounted) {
                          final msg = e.response?.data?['message'] ?? 'Mot de passe actuel incorrect';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: const Color(0xFFA32D2D)),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setModal(() => saving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFE5A01A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5A01A)))
                        : const Text('Modifier', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Field helpers ───────────────────────────────────────────────────────────
  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) =>
    TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 18),
        filled: true, fillColor: const Color(0xFFF5F5F0),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A01A))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) =>
    TextField(
      controller: ctrl,
      obscureText: !show,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF888888), size: 18),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF888888), size: 18),
          onPressed: onToggle,
        ),
        filled: true, fillColor: const Color(0xFFF5F5F0),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5A01A))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE5A01A),
                border: Border.all(color: const Color(0xFFF0EDE5), width: 3),
              ),
              alignment: Alignment.center,
              child: Text(user?.initials ?? 'A',
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 24, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 14),
            Text(user?.fullName ?? '', style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
              child: const Text('Administrateur', style: TextStyle(color: Color(0xFFE5A01A), fontSize: 11)),
            ),
            const SizedBox(height: 24),

            // Menu principal
            _MenuCard(items: [
              _MenuItem(icon: Icons.person,               label: 'Modifier le profil',       onTap: _showEditProfileSheet),
              _MenuItem(icon: Icons.lock_outline,         label: 'Changer le mot de passe',  onTap: _showChangePasswordSheet),
              _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _MenuItem(icon: Icons.bar_chart,            label: 'Rapports & statistiques',
                onTap: () => context.go('/admin/reports')),
            ]),
            const SizedBox(height: 12),

            // Menu secondaire
            _MenuCard(items: [
              _MenuItem(icon: Icons.qr_code, label: "QR code d'entrée",
                onTap: () => context.go('/admin/qr-display')),
            ]),
            const SizedBox(height: 16),

            // Déconnexion
            _PressableButton(
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFA32D2D), size: 16),
                    SizedBox(width: 8),
                    Text('Se déconnecter', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, this.onTap});
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20, color: const Color(0xFF888888)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(item.label, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14))),
                      const Icon(Icons.chevron_right, size: 15, color: Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF5F5F0)),
            ],
          );
        }),
      ),
    );
  }
}

// ── Pressable button with scale feedback ──────────────────────────────────────
class _PressableButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PressableButton({required this.onTap, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: (_pressed && !disableAnimations) ? 0.97 : 1.0,
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 120),
        curve: Curves.easeOutExpo,
        child: widget.child,
      ),
    );
  }
}
