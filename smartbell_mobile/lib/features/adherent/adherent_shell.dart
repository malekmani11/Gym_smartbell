import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'checkin/screens/checkin_scanner_screen.dart';

class AdherentShell extends StatelessWidget {
  final Widget child;
  const AdherentShell({super.key, required this.child});

  static const _tabs = [
    _Tab(icon: Icons.home_outlined,           activeIcon: Icons.home,           label: 'Accueil', path: '/member'),
    _Tab(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Séance',  path: '/member/training'),
    _Tab(icon: Icons.event_outlined,          activeIcon: Icons.event,          label: 'Cours',   path: '/member/courses'),
    _Tab(icon: Icons.person_outline,          activeIcon: Icons.person,         label: 'Profil',  path: '/member/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => t.path == location).clamp(0, _tabs.length - 1);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

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
                // Left tabs: Accueil, Séance
                _buildTab(context, _tabs[0], idx == 0, disableAnimations),
                _buildTab(context, _tabs[1], idx == 1, disableAnimations),

                // Central scan button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinScannerScreen()),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF5F5F0), width: 3),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Color(0xFFE5A01A), size: 22),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right tabs: Cours, Profil
                _buildTab(context, _tabs[2], idx == 2, disableAnimations),
                _buildTab(context, _tabs[3], idx == 3, disableAnimations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, _Tab tab, bool selected, bool disableAnimations) {
    final duration = disableAnimations ? Duration.zero : const Duration(milliseconds: 300);
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(tab.path),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: const Cubic(0.16, 1, 0.3, 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  key: ValueKey('${tab.path}_$selected'),
                  color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  final IconData icon, activeIcon;
  final String label, path;
  const _Tab({required this.icon, required this.activeIcon, required this.label, required this.path});
}
