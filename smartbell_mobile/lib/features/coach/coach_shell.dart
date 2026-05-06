import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/validation_store.dart';
import '../../shared/widgets/gym_bottom_nav.dart';

class CoachShell extends StatefulWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _pendingCount = 0;

  static const _paths = [
    '/coach',
    '/coach/members',
    '/coach/validations',
    '/coach/planning',
    '/coach/absences',
    '/coach/messages',
    '/coach/profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final count = await ValidationStore.pendingCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  List<GymNavItem> get _items => [
    const GymNavItem(icon: Icons.dashboard_outlined,      activeIcon: Icons.dashboard,       label: 'Tableau'),
    const GymNavItem(icon: Icons.people_outline,          activeIcon: Icons.people,          label: 'Membres'),
    GymNavItem(icon: Icons.verified_outlined,             activeIcon: Icons.verified,        label: 'Validations', badgeCount: _pendingCount),
    const GymNavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,  label: 'Planning'),
    const GymNavItem(icon: Icons.event_busy_outlined,     activeIcon: Icons.event_busy,      label: 'Absences'),
    const GymNavItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble,     label: 'Messages'),
    const GymNavItem(icon: Icons.person_outline,          activeIcon: Icons.person,          label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _paths.indexWhere((p) => p == location).clamp(0, _paths.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: child,
      bottomNavigationBar: GymBottomNav(
        currentIndex: idx,
        onTap: (i) {
          context.go(_paths[i]);
          // Refresh badge when navigating away from validations
          Future.delayed(const Duration(milliseconds: 300), _loadPending);
        },
        items: _items,
      ),
    );
  }

  Widget get child => widget.child;
}
