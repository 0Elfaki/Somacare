import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/school_selection_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/student/presentation/student_shell.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/student/presentation/symptom_check_screen.dart';
import '../../features/student/presentation/book_appointment_screen.dart';
import '../../features/student/presentation/my_appointments_screen.dart';
import '../../features/student/presentation/medical_history_screen.dart';
import '../../features/student/presentation/prescriptions_screen.dart';
import '../../features/student/presentation/medical_store_screen.dart';
import '../../features/student/presentation/my_medications_screen.dart';
import '../../features/student/presentation/emergency_screen.dart';
import '../../features/student/presentation/consult_screen.dart';
import '../../features/student/presentation/records_screen.dart';
import '../../features/student/presentation/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',

  routes: [
    // ── Auth / Onboarding (no bottom nav) ─────────────────────
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(
      path: '/school-selection',
      builder: (c, s) => const SchoolSelectionScreen(),
    ),
    GoRoute(
      path: '/student-login',
      builder: (c, s) => const StudentLoginScreen(),
    ),

    // ── Sub-screens pushed on top with back arrow ──────────────
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/book-appointment',
      builder: (c, s) => const BookAppointmentScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/my-appointments',
      builder: (c, s) => const MyAppointmentsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/medical-history',
      builder: (c, s) => const MedicalHistoryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/prescriptions',
      builder: (c, s) => const PrescriptionsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/medical-store',
      builder: (c, s) => const MedicalStoreScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/my-medications',
      builder: (c, s) => const MyMedicationsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/emergency',
      builder: (c, s) => const EmergencyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/consult',
      builder: (c, s) => const ConsultScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/records',
      builder: (c, s) => const RecordsScreen(),
    ),

    // ── Shell (bottom nav tabs only) ───────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => StudentShell(child: child),
      routes: [
        GoRoute(
          path: '/student-dashboard',
          builder: (c, s) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: '/symptom-check',
          builder: (c, s) => const SymptomCheckScreen(),
        ),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Text(state.error?.toString() ?? 'No route for this location'),
    ),
  ),
);
