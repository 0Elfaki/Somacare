import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const _actions = [
    _QuickAction(
      icon: Icons.psychology_outlined,
      label: 'AI Symptom Check',
      color: Color(0xFF9333EA),
      path: '/symptom-check',
    ),
    _QuickAction(
      icon: Icons.calendar_today_outlined,
      label: 'Book Appointment',
      color: Color(0xFF2563EB),
      path: '/book-appointment',
    ),
    _QuickAction(
      icon: Icons.description_outlined,
      label: 'My Appointments',
      color: Color(0xFF059669),
      path: '/my-appointments',
    ),
    _QuickAction(
      icon: Icons.text_snippet_outlined,
      label: 'Medical History',
      color: Color(0xFFD97706),
      path: '/medical-history',
    ),
    _QuickAction(
      icon: Icons.inventory_2_outlined,
      label: 'Prescriptions',
      color: Color(0xFFDB2777),
      path: '/prescriptions',
    ),
    _QuickAction(
      icon: Icons.local_mall_outlined,
      label: 'Medical Store',
      color: Color(0xFF0891B2),
      path: '/medical-store',
    ),
    _QuickAction(
      icon: Icons.error_outline,
      label: 'Emergency',
      color: Color(0xFFDC2626),
      path: '/emergency',
    ),
    _QuickAction(
      icon: Icons.medication_outlined,
      label: 'My Medications',
      color: Color(0xFF7C3AED),
      path: '/my-medications',
    ),
  ];

  Map<String, dynamic>? _upcomingAppointment;
  String _studentName = 'Student';
  bool _loadingAppointment = true;
  bool _initialized = false; // ✅ prevents repeated calls

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _loadingAppointment = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loadingAppointment = false);
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      final appointments = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('student_id', userId)
          .inFilter('status', ['pending', 'confirmed'])
          .order('date', ascending: true)
          .limit(1);

      if (mounted) {
        setState(() {
          _studentName = profile?['full_name'] ?? 'Student';
          _upcomingAppointment = (appointments as List).isNotEmpty
              ? appointments.first
              : null;
          _loadingAppointment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingAppointment = null;
          _loadingAppointment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          _initialized = false; // ✅ allow reload on pull-to-refresh
          await _loadDashboardData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Gradient header ──────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 16,
                      16,
                      92,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B8CFF), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.person_outline,
                              onTap: () => context.go('/profile'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _CircleIconButton(
                              icon: Icons.notifications_none,
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No new notifications'),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Health Status',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    _Pill(text: 'Low Risk'),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '98%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Health Score',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Upcoming card ────────────────────────
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: -77,
                    child: Material(
                      color: Colors.transparent,
                      child: _loadingAppointment
                          ? const SizedBox(
                              height: 80,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _upcomingAppointment == null
                          ? _NoAppointmentCard(
                              onBook: () => context.push('/book-appointment'),
                            )
                          : _UpcomingCard(
                              appointment: _upcomingAppointment!,
                              onJoin: () => context.push('/consult'),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 96),

              // ── Quick Actions ────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, i) =>
                      _QuickActionTile(action: _actions[i]),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Card ─────────────────────────────────────────────────────────────

class _UpcomingCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onJoin;
  const _UpcomingCard({required this.appointment, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] as String;
    final isConfirmed = status == 'confirmed';
    final doctorName = appointment['doctor_name'] ?? 'Doctor';
    final specialty = appointment['doctor_specialty'] ?? '';
    final date = appointment['date'] ?? '';
    final time = appointment['time'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Consultation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$doctorName · $specialty',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isConfirmed ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isConfirmed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFCA8A04),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                '$date · $time',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isConfirmed ? onJoin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(
                isConfirmed ? 'Join Now' : 'Waiting for Doctor Confirmation',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Appointment Card ───────────────────────────────────────────────────────

class _NoAppointmentCard extends StatelessWidget {
  final VoidCallback onBook;
  const _NoAppointmentCard({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No upcoming appointments',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: onBook,
            child: const Text(
              'Book Now',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(action.path),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF16A34A),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
