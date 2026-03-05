import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/medication_provider.dart';
import '../providers/prescription_provider.dart';

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
      isEmergency: true,
    ),
    _QuickAction(
      icon: Icons.medication_outlined,
      label: 'My Medications',
      color: Color(0xFF7C3AED),
      path: '/my-medications',
    ),
  ];

  String _studentName = '';
  bool _initialized = false;

  // For appointments
  Map<String, dynamic>? _upcomingAppointment;
  bool _loadingAppointment = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadName();
      _loadAppointmentData();
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

  Future<void> _loadAppointmentData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now().toIso8601String().split('T').first;
      final appointments = await Supabase.instance.client
          .from('appointments')
          .select('id, date, time, status, doctor_id, notes')
          .eq('student_id', userId)
          .inFilter('status', ['pending', 'confirmed'])
          .gte('date', today)
          .order('date', ascending: true)
          .limit(1);

      if (mounted) {
        setState(() {
          _upcomingAppointment = (appointments as List).isNotEmpty
              ? appointments.first
              : null;
          _loadingAppointment = false;
        });
      }
    } catch (e) {
      debugPrint('Appointment load error: $e');
      if (mounted) {
        setState(() {
          _upcomingAppointment = null;
          _loadingAppointment = false;
        });
      }
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          _initialized = false;
          await _loadName();
          await _loadAppointmentData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient Header ────────────────────────
            SliverToBoxAdapter(
              child: Container(
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
                padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 24),
                child: Row(
                  children: [
                    // ── Avatar ─────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // ── Greeting ───────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_studentName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Actions Label ────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // ── Medication Reminders Widget ─────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildMedicationReminders(),
              ),
            ),

            // ── Upcoming Appointment Widget ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildUpcomingAppointment(),
              ),
            ),

            // ── Quick Actions Grid ─────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _QuickActionTile(action: _actions[i]),
                  childCount: _actions.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Medication Reminders Widget ───────────────────────────────────────────────
  Widget _buildMedicationReminders() {
    return Consumer(
      builder: (context, ref, child) {
        final medicationState = ref.watch(medicationProvider);
        final prescriptionState = ref.watch(prescriptionProvider);

        // Combine reminders from medications and prescriptions
        final List<_DashboardReminder> reminders = [];

        // Add medication reminders
        if (!medicationState.isLoading &&
            medicationState.errorMessage == null) {
          for (final med in medicationState.activeMedications) {
            for (final reminder in med.reminders) {
              if (reminder.isEnabled && reminder.time != null) {
                reminders.add(
                  _DashboardReminder(
                    name: med.name,
                    time: reminder.time!,
                    isPast: _isTimePast(reminder.time!),
                  ),
                );
              }
            }
          }
        }

        // Add prescription reminders
        if (!prescriptionState.isLoading &&
            prescriptionState.errorMessage == null) {
          for (final prescription in prescriptionState.activePrescriptions) {
            for (final reminder in prescription.reminders) {
              if (reminder.isEnabled && reminder.time != null) {
                reminders.add(
                  _DashboardReminder(
                    name:
                        reminder.medicationName ??
                        prescription.medicationName ??
                        'Prescription',
                    time: reminder.time!,
                    isPast: _isTimePast(reminder.time!),
                  ),
                );
              }
            }
          }
        }

        // Sort by time
        reminders.sort((a, b) {
          final aMinutes = a.time.hour * 60 + a.time.minute;
          final bMinutes = b.time.hour * 60 + b.time.minute;
          return aMinutes.compareTo(bMinutes);
        });

        // Show up to 5 reminders
        final displayReminders = reminders.take(5).toList();

        final isLoading =
            medicationState.isLoading || prescriptionState.isLoading;
        final hasError =
            medicationState.errorMessage != null ||
            prescriptionState.errorMessage != null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.alarm,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Medication Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/my-medications'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const SizedBox(
                  height: 85,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (hasError || displayReminders.isEmpty)
                SizedBox(
                  height: 85,
                  child: Center(
                    child: Text(
                      displayReminders.isEmpty
                          ? 'No medication reminders'
                          : 'Failed to load reminders',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 85,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = displayReminders[index];
                      final timeStr = reminder.time.format(context);

                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: reminder.isPast
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              reminder.isPast ? 'Take now' : 'Upcoming',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isTimePast(TimeOfDay time) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final timeMinutes = time.hour * 60 + time.minute;
    return timeMinutes <= nowMinutes;
  }

  // ── Upcoming Appointment Widget ─────────────────────────────────────────────────
  Widget _buildUpcomingAppointment() {
    // Use state variables for real appointment data
    final now = DateTime.now();
    final hasAppointment = _upcomingAppointment != null && !_loadingAppointment;

    if (_loadingAppointment) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading appointments...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!hasAppointment) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No upcoming appointments',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/book-appointment'),
              child: const Text('Book Now'),
            ),
          ],
        ),
      );
    }

    // Parse appointment data
    final appointment = _upcomingAppointment!;
    final dateStr = appointment['date'] as String? ?? '';
    final timeStr = appointment['time'] as String? ?? '';
    final status = appointment['status'] as String? ?? 'pending';
    final doctorId = appointment['doctor_id'] as String?;

    // Build appointment datetime
    DateTime appointmentTime;
    try {
      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');
      appointmentTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        timeParts.isNotEmpty ? int.parse(timeParts[0]) : 0,
        timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
      );
    } catch (e) {
      appointmentTime = now.add(const Duration(hours: 2));
    }

    final formattedTimeStr = _formatAppointmentTime(appointmentTime);
    final canJoin =
        status == 'confirmed' &&
        appointmentTime.difference(now).inMinutes <= 15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_call,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upcoming Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorId != null
                            ? 'Doctor ID: ${doctorId.substring(0, 8)}...'
                            : 'Doctor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canJoin)
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Joining appointment...'),
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam, size: 20),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppointmentTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inMinutes <= 15 && diff.inMinutes >= 0) {
      return 'Starting now';
    } else if (diff.inMinutes < 60) {
      return 'In ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Today at $displayHour:$displayMinute $period';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} ${time.day} at $displayHour:$displayMinute $period';
    }
  }
}

// ── Quick Action Tile ─────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(action.path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: action.isEmergency
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: action.isEmergency
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Model ────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  final bool isEmergency;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
    this.isEmergency = false,
  });
}

// ── Medication Reminder Model ────────────────────────────────────────────────────

class _DashboardReminder {
  final String name;
  final TimeOfDay time;
  final bool isPast;

  const _DashboardReminder({
    required this.name,
    required this.time,
    required this.isPast,
  });
}
