import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/school_selection_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/doctor/presentation/doctor_dashboard_screen.dart';
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

class _SupabaseAuthNotifier extends ChangeNotifier {
  _SupabaseAuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _SupabaseAuthNotifier();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  refreshListenable: _authNotifier,

  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final loc = state.matchedLocation;

    // Always allow school selection in both flows
    if (loc == '/school-selection') return null;

    // Doctor dashboard bypasses student redirect
    if (loc == '/doctor-dashboard') return null;

    final authRoutes = [
      '/onboarding',
      '/role-selection',
      '/student-login',
      '/doctor-login',
    ];
    final isAuthRoute = authRoutes.contains(loc);

    if (loggedIn && isAuthRoute) {
      // ✅ Check role to redirect to correct dashboard
      final userId = session.user.id;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final role = (profile?['role'] as String?) ?? 'student';
      return role == 'doctor' ? '/doctor-dashboard' : '/student-dashboard';
    }

    if (!loggedIn && !isAuthRoute) return '/onboarding';

    return null;
  },

  routes: [
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(
      path: '/role-selection',
      builder: (c, s) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/student-login',
      builder: (c, s) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: '/doctor-login',
      builder: (c, s) => const StudentLoginScreen(),
    ),

    // ✅ Doctor dashboard — top-level route, outside shell
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/doctor-dashboard',
      builder: (c, s) => const DoctorDashboardScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/school-selection',
      builder: (c, s) => const SchoolSelectionScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/book-appointment',
      builder: (c, s) => const BookAppointmentScreen(),
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

    // ── Student shell (bottom nav) ─────────────────────────────
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
        GoRoute(
          path: '/my-appointments',
          builder: (c, s) => const MyAppointmentsScreen(),
        ),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
    ),
  ],

  onException: (context, state, router) {
    router.go('/onboarding');
  },
);
