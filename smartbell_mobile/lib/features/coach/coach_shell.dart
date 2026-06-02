import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachShell extends StatelessWidget {
  final Widget child;
  const CoachShell({super.key, required this.child});

  static const _paths = [
    '/coach',
    '/coach/members',
    '/coach/planning',
    '/coach/messages',
    '/coach/profile',
  ];

  static const _items = [
    _NavItem(icon: Icons.dashboard_outlined,       activeIcon: Icons.dashboard,         label: 'Tableau'),
    _NavItem(icon: Icons.people_outline,           activeIcon: Icons.people,             label: 'Membres'),
    _NavItem(icon: Icons.calendar_month_outlined,  activeIcon: Icons.calendar_month,     label: 'Planning'),
    _NavItem(icon: Icons.chat_bubble_outline,      activeIcon: Icons.chat_bubble,        label: 'Messages'),
    _NavItem(icon: Icons.person_outline,           activeIcon: Icons.person,             label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _paths.indexOf(location).clamp(0, _paths.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: idx,
        items: _items,
        onTap: (i) => context.go(_paths[i]),
      ),
    );
  }
}

// ── Nav item data ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ── Bottom navigation bar ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
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
            }).toList(),
          ),
        ),
      ),
    );
  }
}
