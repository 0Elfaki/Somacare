import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../doctor/data/notification_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  bool _loadingDoctors = true;
  List<Map<String, dynamic>> _doctors = [];
  Map<String, dynamic>? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isEmergency = false; // Emergency/immediate appointment flag

  final List<String> _times = const [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _selectedTime = _times[6];
  }

  Future<void> _loadDoctors() async {
    try {
      // Fetch doctors from profiles table with role='doctor' to get the correct profile IDs
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'doctor');

      if (mounted) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(response);
          _loadingDoctors = false;
          if (_doctors.isNotEmpty) {
            _selectedDoctor = _doctors.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingDoctors = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to load doctors: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _selectedDoctor != null &&
      (_isEmergency || _selectedTime != null) &&
      _reasonCtrl.text.trim().isNotEmpty &&
      !_isLoading;

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // For emergency appointments, set to immediate start
      final appointmentDate = _isEmergency
          ? DateTime.now().toIso8601String().split('T').first
          : _selectedDate.toIso8601String().split('T').first;
      final appointmentTime = _isEmergency ? 'Immediate' : _selectedTime;

      await Supabase.instance.client.from('appointments').insert({
        'student_id': userId,
        'doctor_id': _selectedDoctor!['id'], // This is now the profile ID
        'doctor_name': _selectedDoctor!['full_name'],
        'doctor_specialty':
            _selectedDoctor!['specialization'] ??
            _selectedDoctor!['specialty'] ??
            'General Practice',
        'date': appointmentDate,
        'time': appointmentTime,
        'reason': _reasonCtrl.text.trim(),
        'status': 'pending', // Emergency appointments need doctor approval
        'is_emergency': _isEmergency,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to doctor
      final studentName =
          Supabase.instance.client.auth.currentUser?.email ?? 'Student';
      final doctorId = _selectedDoctor!['id'] as String;
      if (_isEmergency) {
        await NotificationService.notifyEmergency(
          doctorId: doctorId,
          studentName: studentName,
          reason: _reasonCtrl.text.trim(),
        );
      } else {
        await NotificationService.notifyNewBooking(
          doctorId: doctorId,
          studentName: studentName,
          date: appointmentDate,
          time: appointmentTime ?? '',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEmergency
                ? '🚨 Emergency appointment started! Doctor has been notified.'
                : '✅ Appointment booked successfully!',
          ),
          backgroundColor: const Color(0xFF22C55E),
          duration: Duration(seconds: _isEmergency ? 4 : 2),
        ),
      );

      // For emergency, show waiting message and go to dashboard
      if (_isEmergency && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⏳ Emergency request sent! Waiting for doctor to accept.',
            ),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/student-dashboard');
        return;
      }

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to book: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/student-dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Book Appointment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/student-dashboard'),
          ),
        ),
      body: _loadingDoctors
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose doctor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedDoctor,
                          items: _doctors
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    '${d['full_name']} · ${d['specialization'] ?? 'General Practice'}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedDoctor = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isEmergency) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: Color(0xFF475569),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _fmtDate(_selectedDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    ),
                                    lastDate: DateTime(now.year + 1, 12, 31),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Pick'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_isEmergency) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _times.map((t) {
                              final selected = t == _selectedTime;
                              return ChoiceChip(
                                label: Text(t),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _selectedTime = t),
                                selectedColor: const Color(0xFFEFF6FF),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF0F172A),
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFFBFDBFE)
                                      : const Color(0xFFE2E8F0),
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _Card(
                    child: SwitchListTile(
                      title: const Text(
                        'Emergency Appointment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: const Text(
                        'Get immediate consultation',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isEmergency,
                      onChanged: (value) =>
                          setState(() => _isEmergency = value),
                      activeThumbColor: const Color(0xFFDC2626),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reasonCtrl,
                          maxLines: 4,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Example: chest pain, headache, fever…',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm appointment',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
