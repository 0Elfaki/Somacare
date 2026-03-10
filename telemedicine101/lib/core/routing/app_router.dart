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
import '../../features/doctor/presentation/doctor_finances_screen.dart';
import '../../features/doctor/presentation/doctor_patients_screen.dart';

import '../../features/doctor/presentation/notifications_screen.dart';
import '../../features/doctor/presentation/doctor_medical_history_management_screen.dart';

// ── Student imports ───────────────────────────────────────────────────────────
import '../../features/student/presentation/student_shell.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/student/presentation/symptom_check_screen.dart';
import '../../features/student/presentation/book_appointment_screen.dart';
import '../../features/student/presentation/my_appointments_screen.dart';
import '../../features/student/presentation/medical_history_screen.dart';
import '../../features/student/presentation/student_medical_history_view.dart';
import '../../features/student/presentation/prescriptions_screen.dart';
import '../../features/student/presentation/medical_store_screen.dart';
import '../../features/student/presentation/my_medications_screen.dart';
import '../../features/student/presentation/emergency_screen.dart';
import '../../features/student/presentation/consult_screen.dart';
import '../../features/student/presentation/records_screen.dart';
import '../../features/student/presentation/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'studentShell',
);
final _doctorShellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'doctorShell',
);

class _SupabaseAuthNotifier extends ChangeNotifier {
  String? _cachedRole;
  String? get cachedRole => _cachedRole;

  void setCachedRole(String? role) {
    _cachedRole = role;
    notifyListeners();
  }

  void clearCachedRole() {
    _cachedRole = null;
    notifyListeners();
  }

  Future<void> refreshRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _cachedRole = null;
      notifyListeners();
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      final newRole = profile?['role'] as String?;

      // Only update if we got a valid role from DB
      // Keep existing cached role if DB returns null
      if (newRole != null && newRole.isNotEmpty) {
        _cachedRole = newRole;
      }
      // If DB returns null but we have a cached role, keep it
    } catch (e) {
      // On error, keep existing cached role
    }
    notifyListeners();
  }

  _SupabaseAuthNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      // Clear cached role on sign out
      if (event.event == AuthChangeEvent.signedOut) {
        _cachedRole = null;
      }
      // Refresh role on sign in or token refresh
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        await refreshRole();
      }
      notifyListeners();
    });
  }
}

/// Lazy-initialised so no network calls fire until the router is actually used.
_SupabaseAuthNotifier? __authNotifier;
_SupabaseAuthNotifier get _authNotifier =>
    __authNotifier ??= _SupabaseAuthNotifier();

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

    // Route guards: prevent wrong role from accessing wrong dashboard
    if (loggedIn) {
      final role = _authNotifier.cachedRole ?? '';
      // If a student tries to access doctor routes, redirect to student dashboard
      if (role == 'student' &&
          (loc.startsWith('/doctor-') ||
              loc == '/appointment-detail' ||
              loc == '/prescription-writer')) {
        return '/student-dashboard';
      }
      // If a doctor tries to access student routes, redirect to doctor dashboard
      if (role == 'doctor' &&
          (loc.startsWith('/student-') ||
              loc == '/book-appointment' ||
              loc == '/my-appointments' ||
              loc == '/medical-history' ||
              loc == '/prescriptions' ||
              loc == '/medical-store' ||
              loc == '/my-medications' ||
              loc == '/emergency' ||
              loc == '/symptom-check')) {
        return '/doctor-dashboard';
      }
    }

    // Doctor routes bypass the student-specific redirect below
    if (loc.startsWith('/doctor-')) return null;
    if (loc == '/appointment-detail') return null;
    if (loc == '/doctor-consult') return null;
    if (loc == '/student-profile') return null;
    if (loc == '/prescription-writer') return null;

    if (loggedIn && isAuthRoute) {
      // Use cached role if available
      String role = _authNotifier.cachedRole ?? '';

      // Only fetch from DB if we don't have a cached role yet
      // This is necessary for initial route determination
      if (role.isEmpty) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
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
    GoRoute(
      path: '/onboarding',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('onboarding'),
        child: OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/role-selection',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('role-selection'),
        child: RoleSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/student-login',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('student-login'),
        child: StudentLoginScreen(),
      ),
    ),
    GoRoute(
      path: '/doctor-login',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('doctor-login'),
        child: StudentLoginScreen(),
      ),
    ),

    // ── Doctor shell (bottom nav) ──────────────────────────────────────────
    ShellRoute(
      navigatorKey: _doctorShellNavigatorKey,
      builder: (context, state, child) => DoctorShell(child: child),
      routes: [
        GoRoute(
          path: '/doctor-dashboard',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('doctor-dashboard'),
            child: DoctorDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/doctor-appointments',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('doctor-appointments'),
            child: DoctorAppointmentsScreen(),
          ),
        ),
        GoRoute(
          path: '/doctor-finances',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('doctor-finances'),
            child: DoctorFinancesScreen(),
          ),
        ),
        GoRoute(
          path: '/doctor-patients',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('doctor-patients'),
            child: DoctorPatientsScreen(),
          ),
        ),
        GoRoute(
          path: '/doctor/student/:id',
          pageBuilder: (c, s) {
            final id = s.pathParameters['id'];
            final extra = s.extra as Map<String, dynamic>? ?? {};
            return MaterialPage(
              key: ValueKey('doctor-student-$id'),
              child: StudentProfileScreen(
                extra: {
                  ...extra,
                  'studentId': id,
                },
              ),
            );
          },
        ),

        GoRoute(
          path: '/doctor-medical-history/:studentId?',
          pageBuilder: (c, s) {
            final studentId = s.pathParameters['studentId'];
            return MaterialPage(
              key: ValueKey('doctor-medical-history-${studentId ?? 'none'}'),
              child: DoctorMedicalHistoryManagementScreen(studentId: studentId),
            );
          },
        ),
        GoRoute(
          path: '/doctor-profile',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('doctor-profile'),
            child: DoctorProfileScreen(),
          ),
        ),
      ],
    ),

    // Notifications - outside shell for full-screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('notifications'),
        child: NotificationsScreen(),
      ),
    ),

    // ── Doctor full-screen sub-routes (outside shell) ──────────────────────
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/appointment-detail',
      pageBuilder: (c, s) {
        final extra = s.extra;
        final appt = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        final apptId = appt['id'] as String? ?? '';
        return MaterialPage(
          key: ValueKey(
            'appointment-detail-${apptId.isEmpty ? 'none' : apptId}',
          ),
          child: AppointmentDetailScreen(appointment: appt),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/doctor-consult',
      pageBuilder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        final apptId = data['appointmentId'] as String? ?? '';
        return MaterialPage(
          key: ValueKey('doctor-consult-${apptId.isEmpty ? 'none' : apptId}'),
          child: DoctorConsultScreen(extra: data),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/student-profile',
      pageBuilder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        final studentId = data['studentId'] as String? ?? '';
        return MaterialPage(
          key: ValueKey(
            'student-profile-${studentId.isEmpty ? 'none' : studentId}',
          ),
          child: StudentProfileScreen(extra: data),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/prescription-writer',
      pageBuilder: (c, s) {
        final extra = s.extra;
        final data = extra is Map<String, dynamic>
            ? extra
            : <String, dynamic>{};
        final apptId = data['appointmentId'] as String? ?? '';
        return MaterialPage(
          key: ValueKey(
            'prescription-writer-${apptId.isEmpty ? 'none' : apptId}',
          ),
          child: PrescriptionWriterScreen(extra: data),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/doctor/student/:studentId',
      pageBuilder: (c, s) {
        final studentId = s.pathParameters['studentId'] ?? '';
        return MaterialPage(
          key: ValueKey('doctor-student-$studentId'),
          child: StudentProfileScreen(extra: {'studentId': studentId}),
        );
      },
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/school-selection',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('school-selection'),
        child: SchoolSelectionScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/book-appointment',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('book-appointment'),
        child: BookAppointmentScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/medical-history',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('medical-history'),
        child: StudentMedicalHistoryView(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/medical-history-edit',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('medical-history-edit'),
        child: MedicalHistoryScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/prescriptions',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('prescriptions'),
        child: PrescriptionsScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/medical-store',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('medical-store'),
        child: MedicalStoreScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/my-medications',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('my-medications'),
        child: MyMedicationsScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/emergency',
      pageBuilder: (c, s) => const MaterialPage(
        key: ValueKey('emergency'),
        child: EmergencyScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/consult',
      pageBuilder: (c, s) {
        final extra = s.extra;
        final channelId = extra is Map<String, dynamic>
            ? extra['channelId'] as String?
            : null;
        return MaterialPage(
          key: ValueKey('consult-${channelId ?? 'none'}'),
          child: ConsultScreen(channelId: channelId),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/records',
      pageBuilder: (c, s) =>
          const MaterialPage(key: ValueKey('records'), child: RecordsScreen()),
    ),

    // ── Student shell (bottom nav) ─────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => StudentShell(child: child),
      routes: [
        GoRoute(
          path: '/student-dashboard',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('student-dashboard'),
            child: StudentDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/symptom-check',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('symptom-check'),
            child: SymptomCheckScreen(),
          ),
        ),
        GoRoute(
          path: '/my-appointments',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('my-appointments'),
            child: MyAppointmentsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (c, s) => const MaterialPage(
            key: ValueKey('profile'),
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],

  onException: (context, state, router) {
    router.go('/onboarding');
  },
);
