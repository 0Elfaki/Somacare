import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionWriterScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const PrescriptionWriterScreen({super.key, this.extra = const {}});

  @override
  State<PrescriptionWriterScreen> createState() =>
      _PrescriptionWriterScreenState();
}

class _PrescriptionWriterScreenState extends State<PrescriptionWriterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _pharmacyCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  String _frequency = 'Once daily';
  int _durationDays = 7;
  int _refills = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String _doctorName = '';

  static const _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
    'Weekly',
  ];

  static const _durations = [3, 5, 7, 10, 14, 21, 30, 60, 90];

  String get _studentId {
    try {
      final value = widget.extra['studentId'];
      return value?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String get _studentName {
    try {
      final value = widget.extra['studentName'];
      return value?.toString() ?? 'Patient';
    } catch (e) {
      return 'Patient';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  @override
  void dispose() {
    _medicationCtrl.dispose();
    _dosageCtrl.dispose();
    _pharmacyCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _doctorName = (profile?['full_name'] as String?) ?? '';
        });
      }
    } catch (e) {
      // Silently handle error - doctor name is optional
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patient selected. Please go back and try again.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: _durationDays));

      // First, create the prescription
      await Supabase.instance.client.from('prescriptions').insert({
        'student_id': _studentId,
        'doctor_id': userId,
        'medication_name': _medicationCtrl.text.trim(),
        'dosage': _dosageCtrl.text.trim(),
        'frequency': _frequency,
        'prescribing_doctor': 'Dr. $_doctorName',
        'pharmacy': _pharmacyCtrl.text.trim().isEmpty
            ? null
            : _pharmacyCtrl.text.trim(),
        'date_prescribed': now.toIso8601String().split('T').first,
        'expiry_date': expiryDate.toIso8601String().split('T').first,
        'status': 'active',
        'refills_remaining': _refills,
        'refills_total': _refills,
        'instructions': _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Try to add to medical history (optional — table may not exist yet)
      try {
        final medicationEntry =
            '''
Prescription: ${_medicationCtrl.text.trim()}
Dosage: ${_dosageCtrl.text.trim()}
Frequency: $_frequency
Duration: $_durationDays days
Doctor: Dr. $_doctorName
Prescribed: ${now.toIso8601String().split('T').first}
''';

        final existingHistory = await Supabase.instance.client
            .from('medical_histories')
            .select('current_medications')
            .eq('student_id', _studentId)
            .maybeSingle();

        String existingMeds = '';
        if (existingHistory != null &&
            existingHistory['current_medications'] != null) {
          existingMeds = existingHistory['current_medications'] as String;
        }

        final updatedMeds = existingMeds.isEmpty
            ? medicationEntry
            : '$existingMeds\n\n---\n\n$medicationEntry';

        await Supabase.instance.client.from('medical_histories').upsert({
          'student_id': _studentId,
          'current_medications': updatedMeds,
          'updated_at': now.toIso8601String(),
        }, onConflict: 'student_id');
      } catch (_) {
        // medical_histories table may not exist yet — that's OK
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescription issued for $_studentName'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue prescription: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if there was an initialization error
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Write Prescription',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Banner ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prescribing for',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Medication Name ───────────────────────
              const _FieldLabel(label: 'Medication Name *'),
              const SizedBox(height: 6),
              _FormField(
                controller: _medicationCtrl,
                hint: 'e.g. Amoxicillin',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Dosage ────────────────────────────────
              const _FieldLabel(label: 'Dosage *'),
              const SizedBox(height: 6),
              _FormField(
                controller: _dosageCtrl,
                hint: 'e.g. 500mg',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Frequency ─────────────────────────────
              const _FieldLabel(label: 'Frequency *'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequency,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _frequencies
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _frequency = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Duration ──────────────────────────────
              const _FieldLabel(label: 'Duration (days) *'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _durationDays,
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _durations
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d days'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _durationDays = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Refills ───────────────────────────────
              const _FieldLabel(label: 'Refills Allowed'),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_refills > 0) setState(() => _refills--);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF059669),
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '$_refills',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_refills < 10) setState(() => _refills++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Pharmacy ──────────────────────────────
              const _FieldLabel(label: 'Pharmacy (optional)'),
              const SizedBox(height: 6),
              _FormField(
                controller: _pharmacyCtrl,
                hint: 'e.g. Campus Pharmacy',
              ),
              const SizedBox(height: 16),

              // ── Instructions ──────────────────────────
              const _FieldLabel(label: 'Special Instructions (optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _instructionsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Take with food, avoid alcohol...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Issue Prescription',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
