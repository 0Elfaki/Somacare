import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'doctor_medical_history_management_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const StudentProfileScreen({super.key, required this.extra});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _pastAppointments = [];
  List<Map<String, dynamic>> _activePrescriptions = [];
  bool _isLoading = true;

  String get _studentId => (widget.extra['studentId'] as String?) ?? '';
  String get _studentName =>
      (widget.extra['studentName'] as String?) ?? 'Student';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_studentId.isEmpty) return;

      // Load student profile
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _studentId)
          .maybeSingle();

      // Load past appointments with this doctor
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final appointmentsData = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('student_id', _studentId)
          .eq('doctor_id', userId)
          .order('date', ascending: false)
          .limit(10);

      // Load active prescriptions
      final prescriptionsData = await Supabase.instance.client
          .from('prescriptions')
          .select()
          .eq('student_id', _studentId)
          .eq('status', 'active')
          .order('date_prescribed', ascending: false);

      if (mounted) {
        setState(() {
          _profile = profileData;
          _pastAppointments = List<Map<String, dynamic>>.from(appointmentsData);
          _activePrescriptions = List<Map<String, dynamic>>.from(
            prescriptionsData,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  double _bmi(int height, int weight) {
    if (height <= 0) return 0;
    final h = height / 100;
    return weight / (h * h);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF0891B2);
    if (bmi < 25) return const Color(0xFF059669);
    if (bmi < 30) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (_profile?['full_name'] as String?) ?? _studentName;
    final school = (_profile?['school'] as String?) ?? '';
    final height =
        int.tryParse((_profile?['height'] ?? '170').toString()) ?? 170;
    final weight = int.tryParse((_profile?['weight'] ?? '70').toString()) ?? 70;
    final bloodType = (_profile?['blood_type'] as String?) ?? 'A+';
    final bp = (_profile?['blood_pressure'] as String?) ?? '120/80';
    final allergies = (_profile?['allergies'] as String?) ?? '';
    final bmiVal = _bmi(height, weight);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            fullName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
              onPressed: _loadData,
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF059669),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF059669),
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Medical History'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF059669)),
              )
            : TabBarView(
                children: [
                  // Tab 1: Overview
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Patient Header ────────────────────
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
                            Icons.person_outline,
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
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (school.isNotEmpty)
                                Text(
                                  school,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Vitals ────────────────────────────
                  const _SectionHeader(title: 'Vitals'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _VitalCard(
                          label: 'Height',
                          value: '$height cm',
                          icon: Icons.height,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VitalCard(
                          label: 'Weight',
                          value: '$weight kg',
                          icon: Icons.monitor_weight_outlined,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _VitalCard(
                          label: 'BMI',
                          value:
                              '${bmiVal.toStringAsFixed(1)} (${_bmiCategory(bmiVal)})',
                          icon: Icons.analytics_outlined,
                          color: _bmiColor(bmiVal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VitalCard(
                          label: 'Blood Pressure',
                          value: bp,
                          icon: Icons.favorite_outline,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _VitalCard(
                    label: 'Blood Type',
                    value: bloodType,
                    icon: Icons.bloodtype_outlined,
                    color: const Color(0xFFDB2777),
                  ),
                  const SizedBox(height: 20),

                  // ── Allergies ─────────────────────────
                  const _SectionHeader(title: 'Allergies'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: allergies.isEmpty
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: allergies.isEmpty
                            ? const Color(0xFF059669).withValues(alpha: 0.2)
                            : const Color(0xFFD97706).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allergies.isEmpty
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          color: allergies.isEmpty
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            allergies.isEmpty
                                ? 'No known allergies'
                                : allergies,
                            style: TextStyle(
                              color: allergies.isEmpty
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Active Prescriptions ──────────────
                  if (_activePrescriptions.isNotEmpty) ...[
                    const _SectionHeader(title: 'Active Prescriptions'),
                    const SizedBox(height: 10),
                    ..._activePrescriptions.map(
                      (rx) => _PrescriptionChip(prescription: rx),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Past Appointments ─────────────────
                  const _SectionHeader(title: 'Past Appointments'),
                  const SizedBox(height: 10),
                  if (_pastAppointments.isEmpty)
                    const _EmptyState(
                      icon: Icons.event_available_outlined,
                      message: 'No past appointments with you',
                    )
                  else
                    ..._pastAppointments.map(
                      (appt) => _PastAppointmentRow(appointment: appt),
                    ),
                  const SizedBox(height: 20),

                  // ── Medical History Button ─────────────────
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Tab 2: Medical History
            DoctorMedicalHistoryManagementScreen(
              studentId: _studentId,
              isEmbedded: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

// ── Vital Card ────────────────────────────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
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

// ── Prescription Chip ─────────────────────────────────────────────────────────

class _PrescriptionChip extends StatelessWidget {
  final Map<String, dynamic> prescription;
  const _PrescriptionChip({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final name = (prescription['medication_name'] as String?) ?? '';
    final dosage = (prescription['dosage'] as String?) ?? '';
    final frequency = (prescription['frequency'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medication_outlined,
            color: Color(0xFF3B82F6),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  '$dosage · $frequency',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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

// ── Past Appointment Row ──────────────────────────────────────────────────────

class _PastAppointmentRow extends StatelessWidget {
  final Map<String, dynamic> appointment;
  const _PastAppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final date = (appointment['date'] as String?) ?? '';
    final reason = (appointment['reason'] as String?) ?? '';
    final status = (appointment['status'] as String?) ?? '';
    final notes = (appointment['doctor_notes'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notes: $notes',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
