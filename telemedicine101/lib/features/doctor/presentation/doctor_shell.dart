import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorShell extends StatelessWidget {
  final Widget child;
  const DoctorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const _DoctorBottomNav());
  }
}

class _DoctorBottomNav extends StatelessWidget {
  const _DoctorBottomNav();

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/doctor-dashboard')) return 0;
    if (loc.startsWith('/doctor-appointments')) return 1;
    if (loc.startsWith('/doctor-profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ── Home ──────────────────────────────────
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: idx == 0,
                onTap: () => context.go('/doctor-dashboard'),
              ),

              // ── Appointments ──────────────────────────
              _NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Appointments',
                isActive: idx == 1,
                onTap: () => context.go('/doctor-appointments'),
              ),

              // ── Profile ───────────────────────────────
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: idx == 2,
                onTap: () => context.go('/doctor-profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Doctor uses green accent instead of student blue
    final color = isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
