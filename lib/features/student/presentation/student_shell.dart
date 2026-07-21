import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isHome = loc.startsWith('/student-dashboard');

    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isHome) {
          context.go('/student-dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkScreenBg,
        body: child,
        bottomNavigationBar: const _BloomStudentNav(),
      ),
    );
  }
}

class _BloomStudentNav extends StatelessWidget {
  const _BloomStudentNav();

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/student-dashboard')) return 0;
    if (loc.startsWith('/symptom-check')) return 1;
    if (loc.startsWith('/book-appointment')) return 2;
    if (loc.startsWith('/my-appointments')) return 3;
    if (loc.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return BloomStudentBottomNav(
      currentIndex: idx,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/student-dashboard');
          case 1:
            context.go('/symptom-check');
          case 2:
            context.push('/book-appointment');
          case 3:
            context.go('/my-appointments');
          case 4:
            context.go('/profile');
        }
      },
    );
  }
}
