import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/gym_bottom_nav.dart';

class AdherentShell extends StatelessWidget {
  final Widget child;
  const AdherentShell({super.key, required this.child});

  static const _items = [
    GymNavItem(icon: Icons.home_outlined,           activeIcon: Icons.home,             label: 'Accueil'),
    GymNavItem(icon: Icons.fitness_center_outlined,  activeIcon: Icons.fitness_center,   label: 'Séance'),
    GymNavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu,  label: 'Nutrition'),
    GymNavItem(icon: Icons.event_outlined,           activeIcon: Icons.event,            label: 'Cours'),
    GymNavItem(icon: Icons.school_outlined,          activeIcon: Icons.school,           label: 'Coachs'),
    GymNavItem(icon: Icons.chat_outlined,            activeIcon: Icons.chat,             label: 'Messages'),
    GymNavItem(icon: Icons.person_outline,           activeIcon: Icons.person,           label: 'Profil'),
  ];

  static const _paths = [
    '/member',
    '/member/training',
    '/member/nutrition',
    '/member/courses',
    '/member/coaches',
    '/member/chat',
    '/member/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _paths.indexWhere((p) => p == location).clamp(0, _items.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: child,
      bottomNavigationBar: GymBottomNav(
        currentIndex: idx,
        onTap: (i) => context.go(_paths[i]),
        items: _items,
      ),
    );
  }
}
