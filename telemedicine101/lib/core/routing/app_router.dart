import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/school_selection_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/school-selection',
      name: 'schoolSelection',
      builder: (context, state) => const SchoolSelectionScreen(),
    ),
    GoRoute(
      path: '/student-login',
      name: 'studentLogin',
      builder: (context, state) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: '/student-dashboard',
      name: 'studentDashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
  ],
);
