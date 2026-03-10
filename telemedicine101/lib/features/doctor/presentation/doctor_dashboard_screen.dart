import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../data/notification_service.dart';
import 'doctor_medical_history_management_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _emergencyAppointments = [];
  int _unreadNotifications = 0;
  List<Map<String, dynamic>> _pendingApprovals = [];
  RealtimeChannel? _appointmentsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToAppointments();
  }

  @override
  void dispose() {
    _appointmentsChannel?.unsubscribe();
    super.dispose();
  }

  /// Subscribe to real-time appointment changes so the dashboard
  /// auto-refreshes when students book, cancel, or modify appointments.
  void _subscribeToAppointments() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _appointmentsChannel = Supabase.instance.client
        .channel('doctor_appointments_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'doctor_id',
            value: userId,
          ),
          callback: (payload) {
            // Reload data when appointments change
            _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load data in parallel — each query is individually wrapped so one
      // failure (e.g. a missing table) won't block the rest.
      final results = await Future.wait<dynamic>([
        Supabase.instance.client
            .from('appointments')
            .select()
            .eq('doctor_id', userId)
            .eq('is_emergency', true)
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 8), onTimeout: () => <Map<String, dynamic>>[]),
        Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 8), onTimeout: () => null),
        Supabase.instance.client
            .from('appointments')
            .select()
            .eq('doctor_id', userId)
            .eq('date', DateTime.now().toIso8601String().split('T').first)
            .order('time', ascending: true)
            .timeout(const Duration(seconds: 8), onTimeout: () => <Map<String, dynamic>>[]),
        NotificationService.getUnreadNotifications(userId)
            .timeout(const Duration(seconds: 5), onTimeout: () => <Map<String, dynamic>>[]),
        Supabase.instance.client
            .from('appointments')
            .select('student_id')
            .eq('doctor_id', userId)
            .timeout(const Duration(seconds: 8), onTimeout: () => <Map<String, dynamic>>[]),
      ], eagerError: false);

      final allAppts = (results[4] as List?) ?? [];
      final studentIds = allAppts
          .map((a) => a['student_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      List<Map<String, dynamic>> pending = [];
      if (studentIds.isNotEmpty) {
        try {
          final histories = await Supabase.instance.client
              .from('medical_histories')
              .select('id, student_id, updated_at')
              .inFilter('student_id', studentIds)
              .eq('is_approved', false)
              .isFilter('denial_reason', null);

          if (histories.isNotEmpty) {
            final profiles = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name')
                .inFilter('id', studentIds);
            final profileMap = {
              for (var p in profiles) p['id']: p['full_name']
            };
            for (var h in histories) {
              h['student_name'] = profileMap[h['student_id']] ?? 'Unknown Student';
            }
            pending = histories.cast<Map<String, dynamic>>();
          }
        } catch (e) {
          debugPrint('Dashboard pending approvals error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _pendingApprovals = pending;
          _emergencyAppointments = List<Map<String, dynamic>>.from(
            (results[0] as List?) ?? [],
          ).take(5).toList();
          _profile = results[1] as Map<String, dynamic>?;
          _todayAppointments = List<Map<String, dynamic>>.from(
            (results[2] as List?) ?? [],
          ).take(5).toList();
          _unreadNotifications = (results[3] as List?)?.length ?? 0;

          debugPrint(
            'Emergency appointments loaded: ${_emergencyAppointments.length}',
          );
        });
      }
    } catch (e) {
      // Even if the entire batch fails, don't crash — just log
      debugPrint('Dashboard _loadData error: $e');
    }
  }

  Future<void> _approveHistory(String historyId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      await Supabase.instance.client
          .from('medical_histories')
          .update({
            'is_approved': true,
            'approved_by': userId,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', historyId);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History approved.'), backgroundColor: Colors.green),
        );
      }
      _loadData(); // reload
    } catch (e) {
      debugPrint('Error approving: $e');
    }
  }

  Future<void> _denyHistory(String historyId) async {
    final commentController = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Medical History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for denying:'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, commentController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (comment != null && comment.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;
        
        await Supabase.instance.client
            .from('medical_histories')
            .update({
              'is_approved': false,
              'denial_reason': comment,
              'denied_by': userId,
              'denied_at': DateTime.now().toIso8601String(),
            })
            .eq('id', historyId);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History denied.'), backgroundColor: Colors.red),
          );
        }
        _loadData();
      } catch (e) {
        debugPrint('Error denying: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = (_profile?['full_name'] as String?) ?? 'Doctor';
    final specialization =
        (_profile?['specialization'] as String?) ?? 'General Practice';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive breakpoints
              final isMobile = constraints.maxWidth < 600;
              // Calculate columns based on screen size - always use 2 columns
              const actionsColumns = 2;

              // Calculate available height and use it efficiently
              return Padding(
                padding: EdgeInsets.all(
                  isMobile ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    // ── Header with Gradient ───────────────────────────────
                    _DoctorHeader(
                      doctorName: doctorName,
                      specialization: specialization,
                      isMobile: isMobile,
                      onRefresh: _loadData,
                      unreadCount: _unreadNotifications,
                      onNotificationsTap: () => context.push('/notifications'),
                    ),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    // ── Emergency Appointments ──────────────────
                    _EmergencyAppointmentsSection(
                      appointments: _emergencyAppointments,
                      isMobile: isMobile,
                      onViewAll: () =>
                          context.go('/doctor-appointments?status=emergency'),
                      onAppointmentTap: (appt) =>
                          context.push('/appointment-detail', extra: appt),
                    ),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    // ── Quick Actions ─────────────────────
                    _QuickActionsGrid(
                      columns: actionsColumns,
                      isMobile: isMobile,
                      onAllAppointments: () =>
                          context.go('/doctor-appointments'),
                      onFinances: () => context.push('/doctor-finances'),
                      onPatients: () => context.push('/doctor-patients'),
                      onManageHistory: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorMedicalHistoryManagementScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

                    // ── PDF Download Approvals ──────────────────
                    if (_pendingApprovals.isNotEmpty) ...[
                      _PendingApprovalsSection(
                        approvals: _pendingApprovals,
                        onReview: (studentId) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorMedicalHistoryManagementScreen(studentId: studentId),
                          ),
                        ),
                        onApprove: (historyId) => _approveHistory(historyId),
                        onDeny: (historyId) => _denyHistory(historyId),
                      ),
                      SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
                    ],

                    // ── Today's Schedule ──────────────────
                    Expanded(
                      child: _TodaysScheduleSection(
                        appointments: _todayAppointments,
                        isMobile: isMobile,
                        onViewAll: () => context.go('/doctor-appointments'),
                        onAppointmentTap: (appt) =>
                            context.push('/appointment-detail', extra: appt),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Doctor Header ─────────────────────────────────────────────────────────

class _DoctorHeader extends StatelessWidget {
  final String doctorName;
  final String specialization;
  final bool isMobile;
  final VoidCallback onRefresh;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  const _DoctorHeader({
    required this.doctorName,
    required this.specialization,
    required this.isMobile,
    required this.onRefresh,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.lgAll,
            boxShadow: [AppShadows.lg],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Row(
          children: [
            const _DoctorAvatar(size: 44),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DoctorInfo(
                name: doctorName,
                specialization: specialization,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onNotificationsTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const _DoctorAvatar(size: 56),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _DoctorInfo(
            name: doctorName,
            specialization: specialization,
            isDesktop: true,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onNotificationsTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  final double size;

  const _DoctorAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

class _DoctorInfo extends StatelessWidget {
  final String name;
  final String specialization;
  final bool isDesktop;

  const _DoctorInfo({
    required this.name,
    required this.specialization,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop
                ? AppTypography.headlineMedium
                : AppTypography.headlineSmall,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: isDesktop ? AppSpacing.sm : AppSpacing.xs),
        Text(
          specialization,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isDesktop
                ? AppTypography.bodyLarge
                : AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────

// ignore: unused_element
class _StatsRow extends StatelessWidget {
  final int todayCount;
  final int emergencyCount;
  final int completedCount;
  final bool isMobile;

  const _StatsRow({
    required this.todayCount,
    required this.emergencyCount,
    required this.completedCount,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // Use smaller spacing for mobile to prevent overflow
    final cardSpacing = isMobile ? 6.0 : 12.0;

    return Column(
      children: [
        // First Row: Today's Appointments, Emergency, Completed
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: "Today's\nAppointments",
                value: todayCount.toString(),
                icon: Icons.calendar_today_rounded,
                color: AppColors.primary,
                gradient: [AppColors.primary, AppColors.primaryLight],
                onTap: () => context.go('/doctor-appointments'),
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _StatCard(
                label: 'Emergency\nAppointments',
                value: emergencyCount.toString(),
                icon: Icons.emergency_rounded,
                color: AppColors.error,
                gradient: [AppColors.error, const Color(0xFFEF4444)],
                onTap: () =>
                    context.go('/doctor-appointments?status=emergency'),
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _StatCard(
                label: 'Completed\nConsultations',
                value: completedCount.toString(),
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                gradient: [AppColors.success, const Color(0xFF34D399)],
                onTap: () =>
                    context.go('/doctor-appointments?status=completed'),
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pending Approvals Section ─────────────────────────────────────────────

class _PendingApprovalsSection extends StatelessWidget {
  final List<Map<String, dynamic>> approvals;
  final Function(String) onReview;
  final Function(String) onApprove;
  final Function(String) onDeny;

  const _PendingApprovalsSection({
    required this.approvals,
    required this.onReview,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PDF Download Approvals",
              style: TextStyle(
                fontSize: AppTypography.titleMedium,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${approvals.length} Pending',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final approval in approvals) ...[
          _ApprovalCard(
             studentName: approval['student_name'] as String? ?? 'Unknown',
             onReview: () => onReview(approval['student_id'] as String),
             onApprove: () => onApprove(approval['id'] as String),
             onDeny: () => onDeny(approval['id'] as String),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
   final String studentName;
   final VoidCallback onReview;
   final VoidCallback onApprove;
   final VoidCallback onDeny;
   
   const _ApprovalCard({
     required this.studentName,
     required this.onReview,
     required this.onApprove,
     required this.onDeny,
   });
   
   @override
   Widget build(BuildContext context) {
     return InkWell(
       onTap: onReview,
       borderRadius: AppRadius.smAll,
       child: Container(
         padding: const EdgeInsets.all(AppSpacing.md),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: AppRadius.smAll,
           border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
           boxShadow: AppShadows.card,
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFF59E0B), size: 20),
                 ),
                 const SizedBox(width: AppSpacing.md),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         studentName,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       const Text(
                         'Requests PDF download approval',
                         style: TextStyle(color: Colors.grey, fontSize: 13),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 TextButton(
                   onPressed: onReview,
                   child: const Text('Review', style: TextStyle(color: Colors.grey)),
                 ),
                 const SizedBox(width: 8),
                 ElevatedButton(
                   onPressed: onDeny,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.red.shade50,
                     foregroundColor: Colors.red,
                     elevation: 0,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: const Text('Deny'),
                 ),
                 const SizedBox(width: 8),
                 ElevatedButton(
                   onPressed: onApprove,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green,
                     foregroundColor: Colors.white,
                     elevation: 0,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: const Text('Approve'),
                 ),
               ],
             ),
           ],
         ),
       ),
     );
   }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isMobile;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Container(
              height: isMobile ? 85 : 95,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient
                      .map((c) => c.withValues(alpha: 0.15))
                      .toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 3 : 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(icon, color: color, size: isMobile ? 12 : 14),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile
                          ? AppTypography.titleMedium
                          : AppTypography.titleLarge,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 8 : AppTypography.labelSmall,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions Grid ───────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final int columns;
  final bool isMobile;
  final VoidCallback onAllAppointments;
  final VoidCallback onFinances;
  final VoidCallback onPatients;
  final VoidCallback onManageHistory;

  const _QuickActionsGrid({
    required this.columns,
    required this.isMobile,
    required this.onAllAppointments,
    required this.onFinances,
    required this.onPatients,
    required this.onManageHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      // Mobile: Stack vertically with full width
      return Column(
        children: [
          _ActionCard(
            icon: Icons.calendar_month_rounded,
            label: 'All Appointments',
            subtitle: 'View & manage schedules',
            color: AppColors.primary,
            onTap: onAllAppointments,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Finances',
            subtitle: 'Revenue & payments',
            color: const Color(0xFF10B981),
            onTap: onFinances,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionCard(
            icon: Icons.people_rounded,
            label: 'My Patients',
            subtitle: 'View patient records',
            color: const Color(0xFF8B5CF6),
            onTap: onPatients,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionCard(
            icon: Icons.medical_information_rounded,
            label: 'Medical History',
            subtitle: 'Manage records & PDFs',
            color: const Color(0xFFF59E0B),
            onTap: onManageHistory,
            isFullWidth: true,
          ),
        ],
      );
    }

    // Tablet/Desktop: grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.calendar_month_rounded,
                label: 'All Appointments',
                subtitle: 'View & manage schedules',
                color: AppColors.primary,
                onTap: onAllAppointments,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                subtitle: 'Revenue & payments',
                color: const Color(0xFF10B981),
                onTap: onFinances,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.people_rounded,
                label: 'My Patients',
                subtitle: 'View patient records',
                color: const Color(0xFF8B5CF6),
                onTap: onPatients,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _ActionCard(
                icon: Icons.medical_information_rounded,
                label: 'Medical History',
                subtitle: 'Manage records & PDFs',
                color: const Color(0xFFF59E0B),
                onTap: onManageHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: AppTypography.titleSmall,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: AppTypography.labelSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Today's Schedule Section ─────────────────────────────────────────────

class _TodaysScheduleSection extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final bool isMobile;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onAppointmentTap;

  const _TodaysScheduleSection({
    required this.appointments,
    required this.isMobile,
    required this.onViewAll,
    required this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: isMobile
                    ? AppTypography.titleLarge
                    : AppTypography.headlineSmall,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Content
        if (appointments.isEmpty)
          _EmptySchedule()
        else
          _AppointmentsList(
            appointments: appointments,
            isMobile: isMobile,
            onTap: onAppointmentTap,
          ),
      ],
    );
  }
}

class _EmergencyAppointmentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final bool isMobile;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onAppointmentTap;

  const _EmergencyAppointmentsSection({
    required this.appointments,
    required this.isMobile,
    required this.onViewAll,
    required this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Immediate Appointments',
                  style: TextStyle(
                    fontSize: isMobile
                        ? AppTypography.titleLarge
                        : AppTypography.headlineSmall,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Emergency Appointments List
        ...appointments.map(
          (appt) => _EmergencyAppointmentCard(
            appointment: appt,
            onTap: () => onAppointmentTap(appt),
          ),
        ),
      ],
    );
  }
}

class _EmergencyAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const _EmergencyAppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final studentName = (appointment['student_name'] as String?) ?? 'Student';
    final date = (appointment['date'] as String?) ?? '';
    final time = (appointment['time'] as String?) ?? '';
    final reason = (appointment['reason'] as String?) ?? 'No reason provided';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.1),
              AppColors.error.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Emergency Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'IMMEDIATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$date at $time',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right_rounded, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.fullAll,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'No appointments today',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Enjoy your free day!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final bool isMobile;
  final Function(Map<String, dynamic>) onTap;

  const _AppointmentsList({
    required this.appointments,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: appointments.asMap().entries.map((entry) {
        final index = entry.key;
        final appointment = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < appointments.length - 1 ? AppSpacing.md : 0,
          ),
          child: _AppointmentCard(
            appointment: appointment,
            onTap: () => onTap(appointment),
            isMobile: isMobile,
          ),
        );
      }).toList(),
    );
  }
}

// ── My Patients Section ───────────────────────────────────────────────────

// ignore: unused_element
class _MyPatientsSection extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final bool isMobile;

  const _MyPatientsSection({required this.patients, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Patients',
              style: TextStyle(
                fontSize: isMobile
                    ? AppTypography.titleLarge
                    : AppTypography.headlineSmall,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${patients.length} patients',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Content
        if (patients.isEmpty)
          _EmptyPatients()
        else
          _PatientsList(patients: patients, isMobile: isMobile),
      ],
    );
  }
}

class _EmptyPatients extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.fullAll,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'No patients yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Patients will appear here after consultations',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientsList extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final bool isMobile;

  const _PatientsList({required this.patients, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: patients.asMap().entries.map((entry) {
        final index = entry.key;
        final patient = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < patients.length - 1 ? AppSpacing.md : 0,
          ),
          child: _PatientCard(patient: patient, isMobile: isMobile),
        );
      }).toList(),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final bool isMobile;

  const _PatientCard({required this.patient, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final student = patient['student'] as Map<String, dynamic>?;
    final studentName = (student?['full_name'] as String?) ?? 'Unknown';
    final sessionsCount = (patient['sessions_count'] as int?) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (student != null) {
            context.push('/doctor/student/${student['id']}');
          }
        },
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppTypography.bodyMedium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sessionsCount session${sessionsCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: AppTypography.labelSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;
  final bool isMobile;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.isMobile,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (appointment['status'] as String?) ?? 'pending';
    final time = (appointment['time'] as String?) ?? '';
    final reason = (appointment['reason'] as String?) ?? '';
    final studentName = (appointment['student_name'] as String?) ?? 'Student';
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppTypography.bodyMedium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: AppTypography.labelSmall,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Time & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppTypography.bodyMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 10, color: statusColor),
                        const SizedBox(width: 3),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
