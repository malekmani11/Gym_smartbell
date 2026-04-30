import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/course_model.dart';
import '../../models/payment_model.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';

// ─── Shell ───────────────────────────────────────────────────────────────────

class MemberShell extends StatelessWidget {
  final Widget child;
  const MemberShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(label: 'Accueil',      icon: Icons.home_outlined,           activeIcon: Icons.home,           path: '/member'),
    _TabItem(label: 'Cours',        icon: Icons.fitness_center_outlined,  activeIcon: Icons.fitness_center,  path: '/member/courses'),
    _TabItem(label: 'Abonnement',   icon: Icons.card_membership_outlined, activeIcon: Icons.card_membership, path: '/member/subscription'),
    _TabItem(label: 'Paiements',    icon: Icons.receipt_long_outlined,    activeIcon: Icons.receipt_long,    path: '/member/payments'),
    _TabItem(label: 'Profil',       icon: Icons.person_outline,           activeIcon: Icons.person,          path: '/member/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => t.path == location).clamp(0, _tabs.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _GradientBottomNav(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
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

// ─── Gradient bottom nav ──────────────────────────────────────────────────────

class _GradientBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  const _GradientBottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
        ),
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: AppTheme.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final i = e.key;
              final tab = e.value;
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: duration,
                        curve: const Cubic(0.16, 1, 0.3, 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: selected ? AppTheme.navActiveGradient : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedSwitcher(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? tab.activeIcon : tab.icon,
                            key: ValueKey('${i}_$selected'),
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            size: 22,
                            shadows: (selected && !disableAnimations)
                                ? [Shadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 10)]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  List<CourseModel> _allCourses = [];
  SubscriptionModel? _subscription;
  bool _loading = true;

  static const _motivations = [
    'Chaque effort compte. Continue !',
    'Tu es plus fort que tu ne le crois.',
    'La régularité crée les champions.',
    'Un pas de plus vers tes objectifs.',
    'La douleur d\'aujourd\'hui, la force de demain.',
    'Dépasse tes limites chaque jour.',
  ];

  String get _todayMotivation =>
      _motivations[DateTime.now().weekday % _motivations.length];

  String get _todayName {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[DateTime.now().weekday - 1];
  }

  List<CourseModel> get _todayCourses {
    const keys = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
    final today = keys[DateTime.now().weekday - 1];
    return _allCourses.where((c) => c.dayOfWeek?.toUpperCase() == today).toList();
  }

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    try {
      final results = await Future.wait([
        ApiClient().dio.get('/courses', queryParameters: {'size': 50, 'active': true}),
        if (user != null) ApiClient().dio.get('/subscriptions/user/${user.id}', queryParameters: {'size': 1, 'sort': 'createdAt,desc'}),
      ]);

      final coursesData = results[0].data;
      List<dynamic> content = coursesData is Map ? (coursesData['content'] ?? []) : (coursesData ?? []);
      final courses = content.map((e) => CourseModel.fromJson(e)).toList();

      SubscriptionModel? sub;
      if (results.length > 1) {
        final subData = results[1].data;
        final subContent = subData is Map ? (subData['content'] as List?) ?? [] : [];
        if (subContent.isNotEmpty) sub = SubscriptionModel.fromJson(subContent.first);
      }

      setState(() { _allCourses = courses; _subscription = sub; _loading = false; });
    } on DioException {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('SmartBell', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'M',
                              style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour, ${user?.firstName ?? 'Membre'} 👋',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(_todayMotivation, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Aujourd\'hui: $_todayName',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Subscription Status Card ──
                    if (_subscription != null) ...[
                      _SubscriptionMiniCard(sub: _subscription!),
                      const SizedBox(height: 16),
                    ],

                    // ── Quick Stats ──
                    Row(children: [
                      Expanded(child: _StatCard(
                        title: 'Cours aujourd\'hui',
                        value: '${_todayCourses.length}',
                        icon: Icons.today,
                        color: AppColors.info,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                        title: 'Cours cette semaine',
                        value: '${_allCourses.length}',
                        icon: Icons.calendar_month,
                        color: AppColors.success,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                        title: 'Jours restants',
                        value: _subscription != null ? '${_subscription!.daysRemaining}' : '--',
                        icon: Icons.timer_outlined,
                        color: AppColors.warning,
                      )),
                    ]),
                    const SizedBox(height: 20),

                    // ── Today's Schedule ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Programme du jour', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => context.go('/member/courses'),
                          child: const Text('Voir tout', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_todayCourses.isEmpty)
                      _EmptyState(message: 'Aucun cours prévu pour aujourd\'hui', icon: Icons.event_busy)
                    else
                      ...(_todayCourses.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HomeCourseCard(course: c),
                      ))),
                    const SizedBox(height: 20),

                    // ── Quick Actions ──
                    const Text('Actions rapides', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [
                        _QuickActionCard(icon: Icons.fitness_center, label: 'Mes cours', color: AppColors.primary, onTap: () => context.go('/member/courses')),
                        _QuickActionCard(icon: Icons.card_membership, label: 'Abonnement', color: AppColors.success, onTap: () => context.go('/member/subscription')),
                        _QuickActionCard(icon: Icons.receipt_long, label: 'Paiements', color: AppColors.info, onTap: () => context.go('/member/payments')),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Courses Page ─────────────────────────────────────────────────────────────

class MemberCoursesPage extends StatefulWidget {
  const MemberCoursesPage({super.key});

  @override
  State<MemberCoursesPage> createState() => _MemberCoursesPageState();
}

class _MemberCoursesPageState extends State<MemberCoursesPage> with SingleTickerProviderStateMixin {
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;
  int _selectedDay = 0; // 0 = Tous
  final _searchController = TextEditingController();
  String _search = '';

  static const _dayLabels = ['Tous', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _dayKeys   = ['ALL', 'MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];

  List<CourseModel> get _filtered {
    var list = _courses;
    if (_selectedDay > 0) {
      list = list.where((c) => c.dayOfWeek?.toUpperCase() == _dayKeys[_selectedDay]).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.coachName?.toLowerCase().contains(q) ?? false) ||
        (c.location?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.get('/courses', queryParameters: {'size': 100, 'active': true});
      final data = res.data;
      final content = data is Map ? (data['content'] ?? []) : (data ?? []);
      setState(() {
        _courses = (content as List).map((e) => CourseModel.fromJson(e)).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  static const _dayColors = [
    AppColors.primary,
    Color(0xFFE57373), // Lun - rouge
    Color(0xFF81C784), // Mar - vert
    Color(0xFF64B5F6), // Mer - bleu
    Color(0xFFFFB74D), // Jeu - orange
    Color(0xFFBA68C8), // Ven - violet
    Color(0xFF4DB6AC), // Sam - teal
    Color(0xFFF06292), // Dim - rose
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Cours disponibles', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours, coach...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted), onPressed: () { _searchController.clear(); setState(() => _search = ''); })
                        : null,
                    filled: true,
                    fillColor: AppColors.surface2,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ),
              // Day filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _dayLabels.length,
                  itemBuilder: (_, i) {
                    final selected = _selectedDay == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? _dayColors[i] : AppColors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? _dayColors[i] : AppColors.border),
                        ),
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            color: selected ? Colors.black : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? const _EmptyState(message: 'Aucun cours trouvé', icon: Icons.search_off)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CourseCard(course: _filtered[i], accentColor: _dayColors[_dayKeys.indexOf(_filtered[i].dayOfWeek?.toUpperCase() ?? 'ALL').clamp(0, 7)]),
                          ),
                        ),
                ),
    );
  }
}

// ─── Subscription Page ────────────────────────────────────────────────────────

class MemberSubscriptionPage extends StatefulWidget {
  const MemberSubscriptionPage({super.key});

  @override
  State<MemberSubscriptionPage> createState() => _MemberSubscriptionPageState();
}

class _MemberSubscriptionPageState extends State<MemberSubscriptionPage> {
  List<SubscriptionModel> _subscriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final user = context.read<AuthProvider>().user;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final res = await ApiClient().dio.get(
        '/subscriptions/user/${user.id}',
        queryParameters: {'size': 10, 'sort': 'createdAt,desc'},
      );
      final data = res.data;
      final content = data is Map ? (data['content'] ?? []) : [];
      setState(() {
        _subscriptions = (content as List).map((e) => SubscriptionModel.fromJson(e)).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSub = _subscriptions.where((s) => s.isActive).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Mon Abonnement', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Active Subscription Card ──
                        if (activeSub != null)
                          _ActiveSubscriptionCard(sub: activeSub)
                        else
                          _NoSubscriptionCard(),
                        const SizedBox(height: 20),

                        // ── History ──
                        if (_subscriptions.isNotEmpty) ...[
                          const Text('Historique', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._subscriptions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SubscriptionHistoryCard(sub: s),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ─── Payments Page ────────────────────────────────────────────────────────────

class MemberPaymentsPage extends StatefulWidget {
  const MemberPaymentsPage({super.key});

  @override
  State<MemberPaymentsPage> createState() => _MemberPaymentsPageState();
}

class _MemberPaymentsPageState extends State<MemberPaymentsPage> {
  List<PaymentModel> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final user = context.read<AuthProvider>().user;
    try {
      final res = await ApiClient().dio.get('/payments', queryParameters: {
        'size': 50,
        'sort': 'paymentDate,desc',
      });
      final data = res.data;
      final content = data is Map ? (data['content'] ?? data) : data;
      List<PaymentModel> all = (content as List).map((e) => PaymentModel.fromJson(e)).toList();
      // filter by member name client-side
      if (user != null) {
        final name = user.fullName.toLowerCase();
        final filtered = all.where((p) => p.memberName?.toLowerCase() == name).toList();
        all = filtered.isNotEmpty ? filtered : all;
      }
      setState(() { _payments = all; _loading = false; });
    } on DioException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  double get _totalPaid => _payments
      .where((p) => p.status?.toUpperCase() == 'COMPLETED')
      .fold(0.0, (sum, p) => sum + p.amount);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'fr_TN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Mes Paiements', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total payé', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        Text(
                                          '${fmt.format(_totalPaid)} DT',
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${_payments.length} transaction${_payments.length > 1 ? 's' : ''}',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Historique des paiements', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (_payments.isEmpty)
                        const SliverFillRemaining(
                          child: _EmptyState(message: 'Aucun paiement trouvé', icon: Icons.receipt_long_outlined),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _PaymentCard(payment: _payments[i]),
                            ),
                            childCount: _payments.length,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Profile Page ─────────────────────────────────────────────────────────────

class MemberProfilePage extends StatelessWidget {
  const MemberProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = [
      user?.firstName.isNotEmpty == true ? user!.firstName[0] : '',
      user?.lastName.isNotEmpty == true ? user!.lastName[0] : '',
    ].join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
                      ),
                      child: Center(
                        child: Text(initials.isNotEmpty ? initials : 'M', style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(user?.fullName ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Membre', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Section
                  _SectionTitle('Informations personnelles'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _InfoRow(icon: Icons.person_outline,      label: 'Nom complet',  value: user?.fullName ?? '-'),
                    _InfoRow(icon: Icons.email_outlined,      label: 'Email',        value: user?.email ?? '-'),
                    _InfoRow(icon: Icons.badge_outlined,      label: 'Rôle',         value: 'Membre'),
                  ]),
                  const SizedBox(height: 20),

                  // Account Section
                  _SectionTitle('Mon compte'),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    _ActionRow(icon: Icons.card_membership, label: 'Mon abonnement', color: AppColors.success, onTap: () => context.go('/member/subscription')),
                    _ActionRow(icon: Icons.receipt_long,    label: 'Mes paiements',  color: AppColors.info,    onTap: () => context.go('/member/payments')),
                    _ActionRow(icon: Icons.fitness_center,  label: 'Mes cours',      color: AppColors.primary, onTap: () => context.go('/member/courses')),
                  ]),
                  const SizedBox(height: 20),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Déconnexion', style: TextStyle(color: AppColors.textPrimary)),
                            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary))),
                              TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Déconnecter', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Se déconnecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 9), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _HomeCourseCard extends StatelessWidget {
  final CourseModel course;
  const _HomeCourseCard({required this.course});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 50,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              if (course.coachName != null)
                Text('Coach: ${course.coachName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (course.location != null)
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                  Text(course.location!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (course.startTime != null && course.endTime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(course.timeRange, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 4),
            Text('${course.maxParticipants} places', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    ),
  );
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final Color accentColor;
  const _CourseCard({required this.course, required this.accentColor});

  String _fullDayLabel(String? day) {
    const days = {
      'MONDAY': 'Lundi', 'TUESDAY': 'Mardi', 'WEDNESDAY': 'Mercredi',
      'THURSDAY': 'Jeudi', 'FRIDAY': 'Vendredi', 'SATURDAY': 'Samedi', 'SUNDAY': 'Dimanche',
    };
    return days[day?.toUpperCase()] ?? (day ?? '');
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border, width: 0.5),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Row(
      children: [
        // Color side bar
        Container(
          width: 6,
          height: 100,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
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
                    Expanded(
                      child: Text(course.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    if (course.dayOfWeek != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text(_fullDayLabel(course.dayOfWeek), style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (course.coachName != null)
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(course.coachName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (course.startTime != null && course.endTime != null) ...[
                      const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(course.timeRange, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (course.location != null) ...[
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(course.location!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.group_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Max ${course.maxParticipants} participants', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubscriptionMiniCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _SubscriptionMiniCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final pct = sub.totalDays > 0 ? (sub.daysRemaining / sub.totalDays).clamp(0.0, 1.0) : 0.0;
    final color = sub.daysRemaining > 10 ? AppColors.success : (sub.daysRemaining > 3 ? AppColors.warning : AppColors.error);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52, height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: pct, backgroundColor: AppColors.border, color: color, strokeWidth: 5),
                Text('${sub.daysRemaining}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.planName ?? 'Abonnement actif', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${sub.daysRemaining} jours restants', style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('Actif', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _ActiveSubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final pct = sub.totalDays > 0 ? (sub.daysRemaining / sub.totalDays).clamp(0.0, 1.0) : 0.0;
    final color = sub.daysRemaining > 10 ? AppColors.success : (sub.daysRemaining > 3 ? AppColors.warning : AppColors.error);
    final fmt = DateFormat('dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sub.planName ?? 'Plan Standard', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text('Actif', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: pct, backgroundColor: AppColors.border, color: color, strokeWidth: 7),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${sub.daysRemaining}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('jours', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DateInfo(label: 'Début', date: sub.startDate != null ? fmt.format(DateTime.parse(sub.startDate!)) : '-', icon: Icons.play_circle_outline),
              Container(width: 1, height: 40, color: AppColors.border),
              _DateInfo(label: 'Fin', date: sub.endDate != null ? fmt.format(DateTime.parse(sub.endDate!)) : '-', icon: Icons.stop_circle_outlined),
              Container(width: 1, height: 40, color: AppColors.border),
              _DateInfo(label: 'Total', date: '${sub.totalDays} jours', icon: Icons.calendar_month),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  const _DateInfo({required this.label, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: AppColors.textSecondary, size: 18),
    const SizedBox(height: 4),
    Text(date, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
  ]);
}

class _NoSubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(Icons.card_membership_outlined, color: AppColors.textMuted, size: 48),
        const SizedBox(height: 12),
        const Text('Aucun abonnement actif', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Contactez l\'administration pour souscrire à un abonnement.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _SubscriptionHistoryCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _SubscriptionHistoryCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final statusColors = {
      'ACTIVE': AppColors.success,
      'EXPIRED': AppColors.textMuted,
      'CANCELLED': AppColors.error,
      'SUSPENDED': AppColors.warning,
    };
    final statusLabels = {
      'ACTIVE': 'Actif',
      'EXPIRED': 'Expiré',
      'CANCELLED': 'Annulé',
      'SUSPENDED': 'Suspendu',
    };
    final statusKey = sub.status?.toUpperCase() ?? '';
    final color = statusColors[statusKey] ?? AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.card_membership, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.planName ?? 'Abonnement', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                if (sub.startDate != null && sub.endDate != null)
                  Text(
                    '${fmt.format(DateTime.parse(sub.startDate!))} → ${fmt.format(DateTime.parse(sub.endDate!))}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(statusLabels[statusKey] ?? statusKey, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentCard({required this.payment});

  IconData get _methodIcon {
    switch (payment.paymentMethod?.toUpperCase()) {
      case 'CARD': return Icons.credit_card;
      case 'CASH': return Icons.payments_outlined;
      case 'BANK_TRANSFER': return Icons.account_balance;
      case 'ONLINE': return Icons.language;
      default: return Icons.payment;
    }
  }

  Color get _statusColor {
    switch (payment.status?.toUpperCase()) {
      case 'COMPLETED': return AppColors.success;
      case 'PENDING':   return AppColors.warning;
      case 'FAILED':    return AppColors.error;
      case 'REFUNDED':  return AppColors.info;
      default:          return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (payment.status?.toUpperCase()) {
      case 'COMPLETED': return 'Payé';
      case 'PENDING':   return 'En attente';
      case 'FAILED':    return 'Échoué';
      case 'REFUNDED':  return 'Remboursé';
      default:          return payment.status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'fr_TN');
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    DateTime? date;
    try { if (payment.paymentDate != null) date = DateTime.parse(payment.paymentDate!); } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_methodIcon, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentMethod ?? 'Paiement',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (date != null)
                  Text(dateFmt.format(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${fmt.format(payment.amount)} DT', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5), boxShadow: AppTheme.cardShadow),
    child: Column(
      children: children.asMap().entries.map((e) => Column(
        children: [
          e.value,
          if (e.key < children.length - 1) const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
        ],
      )).toList(),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      ]),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de charger les données', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
