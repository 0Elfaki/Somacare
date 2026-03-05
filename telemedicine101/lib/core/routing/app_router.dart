import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/school_selection_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';

// ── Doctor imports ────────────────────────────────────────────────────────────
import '../../features/doctor/presentation/doctor_shell.dart';
import '../../features/doctor/presentation/doctor_dashboard_screen.dart';
import '../../features/doctor/presentation/doctor_appointments_screen.dart';
import '../../features/doctor/presentation/doctor_profile_screen.dart';
import '../../features/doctor/presentation/appointment_detail_screen.dart';
import '../../features/doctor/presentation/doctor_consult_screen.dart';
import '../../features/doctor/presentation/student_profile_screen.dart';
import '../../features/doctor/presentation/prescription_writer_screen.dart';

// ── Student imports ───────────────────────────────────────────────────────────
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
final _doctorShellNavigatorKey = GlobalKey<NavigatorState>();

class _SupabaseAuthNotifier extends ChangeNotifier {
  String? _cachedRole;
  String? get cachedRole => _cachedRole;

  void setCachedRole(String? role) {
    _cachedRole = role;
    notifyListeners();
  }

  void clearCachedRole() {
    _cachedRole = null;
  }

  _SupabaseAuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      // Clear cached role on sign out
      if (event.event == AuthChangeEvent.signedOut) {
        _cachedRole = null;
      }
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

    final authRoutes = [
      '/onboarding',
      '/role-selection',
      '/student-login',
      '/doctor-login',
    ];
    final isAuthRoute = authRoutes.contains(loc);

    // Redirect unauthenticated users to onboarding first
    if (!loggedIn && !isAuthRoute) return '/onboarding';

    // Doctor routes bypass the student-specific redirect below
    // (only reached if loggedIn == true due to check above)
    if (loc.startsWith('/doctor-')) return null;
    if (loc == '/appointment-detail') return null;
    if (loc == '/doctor-consult') return null;
    if (loc == '/student-profile') return null;
    if (loc == '/prescription-writer') return null;

    if (loggedIn && isAuthRoute) {
      // Use cached role to avoid slow database call
      String role = _authNotifier.cachedRole ?? 'student';

      // Only fetch from DB if role not cached
      if (_authNotifier.cachedRole == null) {
        final userId = session.user.id;
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .maybeSingle();
          role = (profile?['role'] as String?) ?? 'student';
          _authNotifier.setCachedRole(role);
        } catch (e) {
          role = 'student';
        }
      }

      return role == 'doctor' ? '/doctor-dashboard' : '/student-dashboard';
    }

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

    // ── Doctor shell (bottom nav) ──────────────────────────────────────────
    ShellRoute(
      navigatorKey: _doctorShellNavigatorKey,
      builder: (context, state, child) => DoctorShell(child: child),
      routes: [
        GoRoute(
          path: '/doctor-dashboard',
          builder: (c, s) => const DoctorDashboardScreen(),
        ),
        GoRoute(
          path: '/doctor-appointments',
          builder: (c, s) => const DoctorAppointmentsScreen(),
        ),
        GoRoute(
          path: '/doctor-profile',
          builder: (c, s) => const DoctorProfileScreen(),
        ),
      ],
    ),

    // ── Doctor full-screen sub-routes (outside shell) ──────────────────────
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/appointment-detail',
      builder: (c, s) {
        final extra = s.extra;
        final appt = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        return AppointmentDetailScreen(appointment: appt);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/doctor-consult',
      builder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        return DoctorConsultScreen(extra: data);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/student-profile',
      builder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        return StudentProfileScreen(extra: data);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/prescription-writer',
      builder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        return PrescriptionWriterScreen(extra: data);
      },
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
      builder: (c, s) {
        final extra = s.extra;
        final channelId = extra is Map<String, dynamic>
            ? extra['channelId'] as String?
            : null;
        return ConsultScreen(channelId: channelId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/records',
      builder: (c, s) => const RecordsScreen(),
    ),

    // ── Student shell (bottom nav) ─────────────────────────────────────────
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
