import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const _quickActions = <_QuickAction>[
    _QuickAction(
      label: 'AI Symptom Check',
      category: 'Wellness',
      path: '/symptom-check',
      icon: Icons.psychology_outlined,
    ),
    _QuickAction(
      label: 'Book Appointment',
      category: 'Scheduling',
      path: '/book-appointment',
      icon: Icons.calendar_today_outlined,
    ),
    _QuickAction(
      label: 'My Appointments',
      category: 'Calendar',
      path: '/my-appointments',
      icon: Icons.event_note_outlined,
    ),
    _QuickAction(
      label: 'Medical History',
      category: 'Records',
      path: '/medical-history',
      icon: Icons.folder_open_outlined,
    ),
    _QuickAction(
      label: 'Prescriptions',
      category: 'Pharmacy',
      path: '/prescriptions',
      icon: Icons.description_outlined,
    ),
    _QuickAction(
      label: 'Medical Store',
      category: 'Shop',
      path: '/medical-store',
      icon: Icons.storefront_outlined,
    ),
    _QuickAction(
      label: 'My Medications',
      category: 'Reminders',
      path: '/my-medications',
      icon: Icons.medication_outlined,
    ),
    _QuickAction(
      label: 'Emergency',
      category: 'Urgent',
      path: '/emergency',
      icon: Icons.emergency_outlined,
      isEmergency: true,
    ),
  ];

  String _studentName = '';
  bool _initialized = false;
  bool _isLoadingStats = true;

  int _upcomingCount = 0;
  int _recordsCount = 0;
  int _medicationsCount = 0;
  Map<String, dynamic>? _nextAppointment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadName();
      _loadDashboardData();
    }
  }

  Future<void> _loadName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          final raw = data?['full_name']?.toString().trim() ?? '';
          if (raw.isNotEmpty) {
            _studentName = raw;
          } else {
            final email =
                Supabase.instance.client.auth.currentUser?.email ?? '';
            _studentName = email.isNotEmpty
                ? email.split('@').first
                : 'Student';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingStats = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingStats = false);
        return;
      }

      final results = await Future.wait<dynamic>([
        Supabase.instance.client
            .from('appointments')
            .select()
            .eq('student_id', userId)
            .order('date', ascending: true)
            .timeout(const Duration(seconds: 8), onTimeout: () => <Map<String, dynamic>>[]),
        Supabase.instance.client
            .from('medications')
            .select('id')
            .eq('student_id', userId)
            .eq('status', 'active')
            .timeout(const Duration(seconds: 8), onTimeout: () => <Map<String, dynamic>>[]),
      ], eagerError: false);

      final appointments = List<Map<String, dynamic>>.from(
        (results[0] as List?) ?? [],
      );
      final medications = List<Map<String, dynamic>>.from(
        (results[1] as List?) ?? [],
      );

      final upcoming = appointments
          .where((a) =>
              ['pending', 'confirmed'].contains(a['status'] as String? ?? ''))
          .toList();
      upcoming.sort((a, b) =>
          (a['date'] as String? ?? '').compareTo(b['date'] as String? ?? ''));

      if (mounted) {
        setState(() {
          _upcomingCount = upcoming.length;
          _recordsCount = appointments.length;
          _medicationsCount = medications.length;
          _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.darkScreenBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _initialized = false;
          await Future.wait([_loadName(), _loadDashboardData()]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: notification bell
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _greeting(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Name
                    Text(
                      _studentName.isNotEmpty
                          ? 'Hi, $_studentName'
                          : 'Hi there',
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 19,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stats pills (real counts)
                    Row(
                      children: [
                        _StatPill(
                          value: _isLoadingStats ? '—' : '$_upcomingCount',
                          label: 'Upcoming',
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          value: _isLoadingStats ? '—' : '$_recordsCount',
                          label: 'Records',
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          value: _isLoadingStats ? '—' : '$_medicationsCount',
                          label: 'Medications',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Upcoming visit card ──────────────────────────────────────────
            if (_nextAppointment != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _UpcomingVisitCard(
                    appointment: _nextAppointment!,
                    onJoin: () => context.push(
                      '/video-waiting-room',
                      extra: {
                        'doctorName':
                            _nextAppointment!['doctor_name'] as String? ??
                                'your doctor',
                        'channelId':
                            'appointment_${_nextAppointment!['id']}',
                      },
                    ),
                    onReschedule: () => context.push('/my-appointments'),
                  ),
                ),
              ),

            // ── Section label ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Text(
                  'Quick actions',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ),
            ),

            // ── Quick Action Grid ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final a = _quickActions[i];
                  return BloomQuickActionTile(
                    category: a.category,
                    label: a.label,
                    icon: a.icon,
                    isEmergency: a.isEmergency,
                    onTap: () => context.push(a.path),
                  );
                }, childCount: _quickActions.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingVisitCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onJoin;
  final VoidCallback onReschedule;

  const _UpcomingVisitCard({
    required this.appointment,
    required this.onJoin,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final doctorName = appointment['doctor_name'] as String? ?? 'Doctor';
    final specialty = appointment['doctor_specialty'] as String? ?? '';
    final date = appointment['date'] as String? ?? '';
    final time = appointment['time'] as String? ?? '';
    final isConfirmed = appointment['status'] == 'confirmed';

    return BloomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING VISIT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: AppColors.darkTextMuted,
                ),
              ),
              Text(
                '$date · $time',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  color: AppColors.darkTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const BloomAvatar(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: BloomDivider(),
          ),
          Row(
            children: [
              Expanded(
                child: BloomButton(
                  label: isConfirmed ? 'Join details' : 'Pending payment',
                  onPressed: isConfirmed ? onJoin : onReschedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BloomButton(
                  label: 'Reschedule',
                  variant: BloomButtonVariant.ghost,
                  onPressed: onReschedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String category;
  final String path;
  final IconData icon;
  final bool isEmergency;
  const _QuickAction({
    required this.label,
    required this.category,
    required this.path,
    required this.icon,
    this.isEmergency = false,
  });
}
