import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _todayAppointments = [];
  int _pendingCount = 0;
  int _completedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load doctor profile
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final today = DateTime.now().toIso8601String().split('T').first;

      // Load today's appointments
      final todayData = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('doctor_id', userId)
          .eq('date', today)
          .order('time', ascending: true);

      // Load pending count
      final pendingData = await Supabase.instance.client
          .from('appointments')
          .select('id')
          .eq('doctor_id', userId)
          .eq('status', 'pending');

      // Load completed count
      final completedData = await Supabase.instance.client
          .from('appointments')
          .select('id')
          .eq('doctor_id', userId)
          .eq('status', 'completed');

      if (mounted) {
        setState(() {
          _profile = profileData;
          _todayAppointments = List<Map<String, dynamic>>.from(
            todayData,
          ).take(5).toList();
          _pendingCount = (pendingData as List).length;
          _completedCount = (completedData as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = (_profile?['full_name'] as String?) ?? 'Doctor';
    final specialization =
        (_profile?['specialization'] as String?) ?? 'General Practice';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF059669),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF0891B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. $doctorName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              specialization,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stats Row ────────────────────────────
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: "Today",
                          value: _todayAppointments.length.toString(),
                          icon: Icons.today_outlined,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: "Pending",
                          value: _pendingCount.toString(),
                          icon: Icons.pending_outlined,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: "Completed",
                          value: _completedCount.toString(),
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ─────────────────────
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'All Appointments',
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                          onTap: () => context.go('/doctor-appointments'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.description_outlined,
                          label: 'Write Prescription',
                          color: const Color(0xFF0891B2),
                          bgColor: const Color(0xFFECFEFF),
                          onTap: () => context.push(
                            '/prescription-writer',
                            extra: <String, dynamic>{},
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Today's Schedule ──────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/doctor-appointments'),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_todayAppointments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No appointments today',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_todayAppointments.map(
                      (appt) => _AppointmentCard(
                        appointment: appt,
                        onTap: () =>
                            context.push('/appointment-detail', extra: appt),
                      ),
                    )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appointment, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'completed':
        return const Color(0xFF0891B2);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (appointment['status'] as String?) ?? 'pending';
    final time = (appointment['time'] as String?) ?? '';
    final reason = (appointment['reason'] as String?) ?? '';
    final studentName = (appointment['student_name'] as String?) ?? 'Student';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF059669),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
