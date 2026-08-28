import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const _quickActions = <_QuickAction>[
    _QuickAction(
      label: 'Message Doctor',
      category: 'Chat',
      path: '/messaging-chat',
      icon: Icons.chat_bubble_outline,
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
  ];

  static const _quickActionColors = <Color>[
    AppColors.medPrimaryBlue,
    AppColors.medTeal,
    AppColors.medPurple,
    AppColors.medAmber,
    AppColors.medPrimaryBlue,
    AppColors.medTeal,
    AppColors.medPurple,
  ];

  String _studentName = '';
  bool _initialized = false;
  bool _isLoadingStats = true;

  int _upcomingCount = 0;
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
      backgroundColor: AppColors.medBg,
      body: RefreshIndicator(
        color: AppColors.medPrimaryBlue,
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
                padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 16),
                color: AppColors.medBg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.medTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _studentName.isNotEmpty
                                ? 'Hi, $_studentName 👋'
                                : 'Hi there 👋',
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: AppColors.medTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MedIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Stat cards (real counts) ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MedStatCard(
                        icon: Icons.event_available,
                        value: _isLoadingStats ? '—' : '$_upcomingCount',
                        label: 'Upcoming\nAppointments',
                        color: AppColors.medPrimaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MedStatCard(
                        icon: Icons.medication_outlined,
                        value: _isLoadingStats ? '—' : '$_medicationsCount',
                        label: 'Active\nMedications',
                        color: AppColors.medTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Upcoming visit card ──────────────────────────────────────────
            if (_nextAppointment != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

            // ── Emergency hero banner ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _MedHeroBanner(
                  icon: Icons.emergency_outlined,
                  eyebrow: 'URGENT CARE',
                  title: 'Talk to a doctor in minutes',
                  subtitle:
                      'For symptoms that need attention now — connect with an on-call doctor right away.',
                  gradientColors: const [
                    AppColors.medRed,
                    Color(0xFF991B1B),
                  ],
                  primaryLabel: 'CONNECT NOW',
                  onPrimaryTap: () => context.push('/emergency'),
                  secondaryLabel: 'See all requests',
                  onSecondaryTap: () => context.push('/my-appointments'),
                ),
              ),
            ),

            // ── AI Symptom Checker hero banner ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _MedHeroBanner(
                  icon: Icons.psychology_outlined,
                  eyebrow: 'AI SYMPTOM CHECKER',
                  title: 'Describe your symptoms',
                  subtitle:
                      'Get instant AI-guided insight into what you\'re feeling and what to do next.',
                  gradientColors: const [
                    AppColors.medPurple,
                    AppColors.medPrimaryBlue,
                  ],
                  primaryLabel: 'START CHECK',
                  onPrimaryTap: () => context.push('/symptom-check'),
                ),
              ),
            ),

            // ── Medication reminders card ────────────────────────────────────
            if (!_isLoadingStats && _medicationsCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _MedReminderCard(
                    count: _medicationsCount,
                    onTap: () => context.push('/my-medications'),
                  ),
                ),
              ),

            // ── Section label ────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  'Quick actions',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.medTextPrimary,
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
                  return _MedQuickActionCard(
                    category: a.category,
                    label: a.label,
                    icon: a.icon,
                    color: _quickActionColors[i % _quickActionColors.length],
                    onTap: () => context.push(a.path),
                  );
                }, childCount: _quickActions.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.medCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.medBorder),
      ),
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
                  color: AppColors.medPrimaryBlue,
                ),
              ),
              Text(
                '$date · $time',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  color: AppColors.medTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.medPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
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
                        color: AppColors.medTextPrimary,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.medTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.medBorder),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isConfirmed ? onJoin : onReschedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medPrimaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isConfirmed ? 'Join details' : 'Pending payment',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReschedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.medTextPrimary,
                    side: const BorderSide(color: AppColors.medBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular icon button used in the header (notification bell, etc.) —
/// light-card style to match the Damulink header.
class _MedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MedIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.medCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.medBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.medTextPrimary),
      ),
    );
  }
}

/// White stat card with a colored icon chip, value, and label — the
/// Damulink-style replacement for the old dark stat pills.
class _MedStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MedStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.medCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.medBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.medTextPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    height: 1.2,
                    color: AppColors.medTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width gradient hero banner (Emergency / AI Symptom Checker), matching
/// the Damulink "EMERGENCY NEED FOR BLOOD DONORS" card pattern.
class _MedHeroBanner extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  const _MedHeroBanner({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  eyebrow,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: onPrimaryTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradientColors.first,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onSecondaryTap,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(
                    secondaryLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Amber "N reminders today" card, tapping through to My Medications.
class _MedReminderCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MedReminderCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.medAmber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.medAmber.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.medAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.medAmber,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication reminders',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.medTextPrimary,
                    ),
                  ),
                  Text(
                    'You have $count active medication${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.medTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.medTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored quick-action tile, matching Damulink's solid-color grid cards
/// (Request Blood / Lab Report / Appointments / Blood Journey, etc).
class _MedQuickActionCard extends StatelessWidget {
  final String category;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MedQuickActionCard({
    required this.category,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String category;
  final String path;
  final IconData icon;
  const _QuickAction({
    required this.label,
    required this.category,
    required this.path,
    required this.icon,
  });
}
