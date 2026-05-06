import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GymNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  const GymNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class GymBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GymNavItem> items;

  const GymBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
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
        border: const Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        boxShadow: AppTheme.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
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
                      // Active pill + icon
                      AnimatedContainer(
                        duration: duration,
                        curve: const Cubic(0.16, 1, 0.3, 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: selected ? AppTheme.navActiveGradient : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: disableAnimations
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              child: Icon(
                                selected ? item.activeIcon : item.icon,
                                key: ValueKey('${i}_$selected'),
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                size: 22,
                                shadows: selected && !disableAnimations
                                    ? [
                                        Shadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.6),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.error
                                            .withValues(alpha: 0.45),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    item.badgeCount > 9
                                        ? '9+'
                                        : '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        child: Text(item.label),
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
