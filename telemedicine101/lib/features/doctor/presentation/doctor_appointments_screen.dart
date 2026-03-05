import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get doctor's name from profile
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      final doctorName = profile['full_name'] as String?;
      if (doctorName == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch appointments for this doctor by ID
      final data = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('doctor_id', userId)
          .order('date', ascending: false);

      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filter(List<String> statuses) =>
      _appointments.where((a) => statuses.contains(a['status'])).toList();

  @override
  Widget build(BuildContext context) {
    final upcoming = _filter(['pending', 'confirmed']);
    final completed = _filter(['completed']);
    final cancelled = _filter(['cancelled']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Appointments',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF059669),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : TabBarView(
              controller: _tab,
              children: [
                _AppointmentList(
                  appointments: upcoming,
                  emptyMessage: 'No upcoming appointments',
                  emptyIcon: Icons.event_available_outlined,
                  onRefresh: _loadAppointments,
                ),
                _AppointmentList(
                  appointments: completed,
                  emptyMessage: 'No completed appointments',
                  emptyIcon: Icons.check_circle_outline,
                  onRefresh: _loadAppointments,
                ),
                _AppointmentList(
                  appointments: cancelled,
                  emptyMessage: 'No cancelled appointments',
                  emptyIcon: Icons.cancel_outlined,
                  onRefresh: _loadAppointments,
                ),
              ],
            ),
    );
  }
}

// ── Appointment List ──────────────────────────────────────────────────────────

class _AppointmentList extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF059669),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return _DoctorAppointmentCard(
            appointment: appt,
            onTap: () => context.push('/appointment-detail', extra: appt),
          );
        },
      ),
    );
  }
}

// ── Doctor Appointment Card ───────────────────────────────────────────────────

class _DoctorAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.onTap,
  });

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
    final date = (appointment['date'] as String?) ?? '';
    final time = (appointment['time'] as String?) ?? '';
    final reason = (appointment['reason'] as String?) ?? '';
    final studentName = (appointment['student_name'] as String?) ?? 'Student';
    final school = (appointment['school'] as String?) ?? '';
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (school.isNotEmpty)
                        Text(
                          school,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_outlined,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF059669),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
