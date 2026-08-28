import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_ui.dart';

/// The student side's persistent chrome.
///
/// Shares [AppBottomNav] with the doctor shell so both halves of the app move
/// and look the same; only the accent colour and destinations differ.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isHome = loc.startsWith('/student-dashboard');

    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isHome) context.go('/student-dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: child,
        bottomNavigationBar: const _StudentBottomNav(),
      ),
    );
  }
}

class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav();

  static const _tabs = <String>[
    '/student-dashboard',
    '/symptom-check',
    '/book-appointment',
    '/my-appointments',
    '/profile',
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);

    return AppBottomNav(
      currentIndex: index,
      accent: AppColors.studentAccent,
      destinations: [
        AppNavDestination(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Home',
          onTap: () => context.go('/student-dashboard'),
        ),
        AppNavDestination(
          icon: Icons.psychology_outlined,
          activeIcon: Icons.psychology_rounded,
          label: 'AI Check',
          onTap: () => context.go('/symptom-check'),
        ),
        AppNavDestination(
          icon: Icons.add_circle_outline_rounded,
          activeIcon: Icons.add_circle_rounded,
          label: 'Book',
          onTap: () => context.push('/book-appointment'),
        ),
        AppNavDestination(
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note_rounded,
          label: 'Visits',
          onTap: () => context.go('/my-appointments'),
        ),
        AppNavDestination(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }
}
