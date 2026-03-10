import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Map<String, dynamic> _appointment;
  Map<String, dynamic>? _studentProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  late final TextEditingController _notesCtrl;

  static const _statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _appointment = Map<String, dynamic>.from(widget.appointment);
    _notesCtrl = TextEditingController(
      text: (_appointment['doctor_notes'] as String?) ?? '',
    );
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    setState(() => _isLoading = true);
    try {
      final studentId = _appointment['student_id'] as String?;
      if (studentId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', studentId)
            .maybeSingle();
        if (mounted) setState(() => _studentProfile = data);
      }
    } catch (_) {
      // Profile load failure is non-critical
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    try {
      final id = _appointment['id'] as String?;
      if (id == null || id.isEmpty) return;
      await Supabase.instance.client
          .from('appointments')
          .update({'doctor_notes': _notesCtrl.text.trim()})
          .eq('id', id);

      setState(() {
        _appointment['doctor_notes'] = _notesCtrl.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final id = _appointment['id'] as String?;
      if (id == null || id.isEmpty) return;
      await Supabase.instance.client
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', id);

      setState(() => _appointment['status'] = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

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
    final status = (_appointment['status'] as String?) ?? 'pending';
    final date = (_appointment['date'] as String?) ?? '';
    final time = (_appointment['time'] as String?) ?? '';
    final reason = (_appointment['reason'] as String?) ?? '';
    final appointmentId = (_appointment['id'] as String?) ?? '';
    final studentId = (_appointment['student_id'] as String?) ?? '';

    final studentName =
        (_studentProfile?['full_name'] as String?) ??
        (_appointment['student_name'] as String?) ??
        'Student';
    final school =
        (_studentProfile?['school'] as String?) ??
        (_appointment['school'] as String?) ??
        '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/doctor-dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => context.go('/doctor-dashboard'),
          ),
          title: const Text(
          'Appointment Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Student Info ──────────────────────
                  _SectionCard(
                    title: 'Patient',
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF059669),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (school.isNotEmpty)
                                Text(
                                  school,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (studentId.isNotEmpty)
                          TextButton(
                            onPressed: () => context.push(
                              '/student-profile',
                              extra: <String, dynamic>{
                                'studentId': studentId,
                                'studentName': studentName,
                              },
                            ),
                            child: const Text(
                              'View Profile',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Appointment Info ──────────────────
                  _SectionCard(
                    title: 'Appointment',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: date,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Time',
                          value: time,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.notes_outlined,
                          label: 'Reason',
                          value: reason,
                        ),
                        const SizedBox(height: 14),
                        // Status selector
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: status,
                              underline: const SizedBox(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              items: _statuses
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s[0].toUpperCase() + s.substring(1),
                                        style: TextStyle(
                                          color: _statusColor(s),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null && val != status) {
                                  _updateStatus(val);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Doctor Notes ──────────────────────
                  _SectionCard(
                    title: 'Doctor Notes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Add clinical notes, observations...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Notes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ────────────────────
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Join Video Call
                  if (status == 'pending' || status == 'confirmed')
                    _ActionTile(
                      icon: Icons.videocam_outlined,
                      label: 'Join Video Consultation',
                      subtitle: 'Start Agora video call with patient',
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                      onTap: () => context.push(
                        '/doctor-consult',
                        extra: <String, dynamic>{
                          'appointmentId': appointmentId,
                          'studentName': studentName,
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Write Prescription
                  _ActionTile(
                    icon: Icons.description_outlined,
                    label: 'Write Prescription',
                    subtitle: 'Issue medication prescription for patient',
                    color: const Color(0xFF0891B2),
                    bgColor: const Color(0xFFECFEFF),
                    onTap: () => context.push(
                      '/prescription-writer',
                      extra: <String, dynamic>{
                        'studentId': studentId,
                        'studentName': studentName,
                        'appointmentId': appointmentId,
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // View Student Profile
                  if (studentId.isNotEmpty)
                    _ActionTile(
                      icon: Icons.person_outline,
                      label: 'View Patient Profile',
                      subtitle: 'See vitals, allergies, and medical history',
                      color: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                      onTap: () => context.push(
                        '/student-profile',
                        extra: <String, dynamic>{
                          'studentId': studentId,
                          'studentName': studentName,
                        },
                      ),
                    ),

                ],
              ),
            ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
