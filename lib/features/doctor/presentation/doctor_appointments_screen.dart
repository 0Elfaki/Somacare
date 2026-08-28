import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

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
    debugPrint('DEBUG: initState called - loading appointments');
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
      if (userId == null) {
        debugPrint('Error: No user logged in');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Loading appointments for user: $userId');

      // Try to fetch appointments directly by doctor_id
      var data = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('doctor_id', userId)
          .order('created_at', ascending: false);

      debugPrint('Appointments found by doctor_id ($userId): ${data.length}');

      // If no results by ID, try by doctor_name
      if (data.isEmpty) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('full_name, id')
              .eq('id', userId)
              .maybeSingle();

          debugPrint('Doctor profile: $profile');

          if (profile != null) {
            final doctorName = profile['full_name'] as String?;
            final doctorProfileId = profile['id'] as String?;

            debugPrint(
              'Doctor Name: $doctorName, Profile ID: $doctorProfileId',
            );

            // Try by doctor_name
            if (doctorName != null) {
              data = await Supabase.instance.client
                  .from('appointments')
                  .select()
                  .eq('doctor_name', doctorName)
                  .order('created_at', ascending: false);
              debugPrint('Appointments found by doctor_name: ${data.length}');
            }

            // Also try by profile ID if still empty
            if (data.isEmpty && doctorProfileId != null) {
              data = await Supabase.instance.client
                  .from('appointments')
                  .select()
                  .eq('doctor_id', doctorProfileId)
                  .order('created_at', ascending: false);
              debugPrint('Appointments found by profile ID: ${data.length}');
            }
          }
        } catch (e) {
          debugPrint('Error fetching profile: $e');
        }
      }

      // If still no results, try fetching all (for debugging)
      if (data.isEmpty) {
        try {
          final allApts = await Supabase.instance.client
              .from('appointments')
              .select()
              .order('created_at', ascending: false)
              .limit(20);
          debugPrint('All appointments in DB: ${allApts.length}');
          if (allApts.isNotEmpty) {
            data = allApts;
          }
        } catch (e) {
          debugPrint('Error fetching all appointments: $e');
        }
      }

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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILD: All appointments: ${_appointments.length}');

    return Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to dashboard',
            onPressed: () => context.go('/doctor-dashboard'),
          ),
          title: const Text('Appointments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAppointments,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            tabs: [
              Tab(text: 'All (${_appointments.length})'),
              const Tab(text: 'Upcoming'),
              const Tab(text: 'Completed'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                controller: _tab,
                children: [
                  // Tab 0: All appointments
                  _buildSimpleList(_appointments, 'All'),
                  // Tab 1: Upcoming (pending, confirmed)
                  _buildSimpleList(
                    _appointments
                        .where(
                          (a) =>
                              a['status'] == 'pending' ||
                              a['status'] == 'confirmed' ||
                              a['status'] == 'emergency',
                        )
                        .toList(),
                    'Upcoming',
                  ),
                  // Tab 2: Completed
                  _buildSimpleList(
                    _appointments
                        .where((a) => a['status'] == 'completed')
                        .toList(),
                    'Completed',
                  ),
                ],
      ),
    );
  }

  Widget _buildSimpleList(List<Map<String, dynamic>> items, String label) {
    debugPrint('Building $label list with ${items.length} items');

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No appointments in $label',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appt = items[index];
        final studentName = (appt['student_name'] as String?) ?? 'Student';
        final date = (appt['date'] as String?) ?? '';
        final time = (appt['time'] as String?) ?? '';
        final status = (appt['status'] as String?) ?? 'unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                studentName.toString().isNotEmpty
                    ? studentName.toString()[0].toUpperCase()
                    : 'S',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: Text(studentName.toString()),
            subtitle: Text('$date at $time'),
            trailing: Chip(
              label: Text(status.toString().toUpperCase()),
              backgroundColor: _getStatusColor(
                status.toString(),
              ).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _getStatusColor(status.toString()),
                fontSize: 12,
              ),
            ),
            onTap: () {
              context.push('/appointment-detail', extra: appt);
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}
