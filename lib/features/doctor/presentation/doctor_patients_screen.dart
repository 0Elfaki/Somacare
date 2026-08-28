import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_ui.dart';

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
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text('My patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: _isLoading
          // A skeleton keeps the page from jumping when the rows arrive, and
          // tells the doctor what is coming rather than just that something is.
          ? ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, _) => const AppSkeletonRow(),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: AppErrorState(
                    message: _error!,
                    onRetry: _loadPatients,
                  ),
                )
              : _patients.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      child: AppEmptyState(
                        icon: Icons.groups_outlined,
                        title: 'No patients yet',
                        message:
                            'Once a student books a consultation with you, '
                            'they will appear here with their visit history.',
                        actionLabel: 'Open my schedule',
                        onAction: () => context.go('/doctor-appointments'),
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
                            side: const BorderSide(color: AppColors.border),
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
                                    const Icon(Icons.school, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        school,
                                        style: const TextStyle(color: AppColors.textMuted),
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
                              color: AppColors.textMuted,
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
