import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // 1. Get all unique students from the doctor's appointments
      final appointments = await Supabase.instance.client
          .from('appointments')
          .select('student_id')
          .eq('doctor_id', userId);

      final studentIds = appointments
          .map((a) => a['student_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (studentIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch profiles for those students
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .inFilter('id', studentIds);

      final profiles = List<Map<String, dynamic>>.from(profilesResponse);

      // 3. Count appointments per student
      final Map<String, int> appointmentCounts = {};
      for (var appt in appointments) {
        final sid = appt['student_id'] as String;
        appointmentCounts[sid] = (appointmentCounts[sid] ?? 0) + 1;
      }

      // 4. Combine data
      final List<Map<String, dynamic>> patientsData = profiles.map((p) {
        return {
          ...p,
          'appointment_count': appointmentCounts[p['id']] ?? 0,
        };
      }).toList();

      // Sort alphabetically by name
      patientsData.sort((a, b) {
        final nameA = (a['full_name'] ?? a['email'] ?? '').toString().toLowerCase();
        final nameB = (b['full_name'] ?? b['email'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _patients = patientsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patients: $e');
      setState(() {
        _error = 'Failed to load patients. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPatients,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _patients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No patients found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Patients will appear here once you have appointments with them.',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _patients.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final patient = _patients[index];
                        final name =
                            (patient['full_name'] ?? patient['email'] ?? 'Unknown').toString();
                        final school = (patient['school'] ?? 'No school given').toString();
                        final appointmentCount = patient['appointment_count'] ?? 0;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.school, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        school,
                                        style: const TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$appointmentCount Appointment${appointmentCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              context.push(
                                '/doctor/student/${patient['id']}',
                                extra: {
                                  'studentName': name,
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
