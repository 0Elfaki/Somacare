import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAppointments();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tab.dispose();
    super.dispose();
  }

  void _subscribeToChanges() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _channel = Supabase.instance.client
        .channel('student_appointments_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: userId,
          ),
          callback: (_) => _loadAppointments(),
        )
        .subscribe();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('StudentAppointments: No user logged in');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      debugPrint('StudentAppointments: Loading for userId: $userId');

      final data = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('student_id', userId)
          .order('date', ascending: true);

      debugPrint('StudentAppointments: Found ${data.length} appointments');
      debugPrint('StudentAppointments: Raw data: $data');

      if (mounted) {
        setState(() => _appointments = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('StudentAppointments: Error loading appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(String id) async {
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', id);
      await _loadAppointments(); // ✅ refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filter(List<String> statuses) => _appointments
      .where((a) => statuses.contains(a['status'] ?? 'pending'))
      .toList();

  @override
  Widget build(BuildContext context) {
    // Show all appointments in upcoming - be more inclusive with statuses
    final upcoming = _filter([
      'pending',
      'confirmed',
      'pending_confirmation',
      'approved',
      'in_progress',
      '',
    ]);
    final completed = _filter(['completed', 'done', 'finished']);
    final cancelled = _filter(['cancelled', 'rejected', 'declined']);

    // Debug: show what statuses exist
    final allStatuses = _appointments
        .map((a) => a['status'] ?? '(null)')
        .toSet();
    debugPrint('StudentAppointments: All statuses found: $allStatuses');
    debugPrint(
      'StudentAppointments: Total: ${_appointments.length}, Upcoming: ${upcoming.length}, Completed: ${completed.length}, Cancelled: ${cancelled.length}',
    );

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.go('/student-dashboard'),
          ),
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: AppTypography.headlineSmall,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppTypography.labelMedium,
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
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tab,
              children: [
                _ListTab(
                  items: upcoming,
                  emptyText: 'No upcoming appointments yet.',
                  emptyIcon: Icons.calendar_today_outlined,
                  onJoin: (a) => context.push(
                    '/video-waiting-room',
                    extra: {
                      'doctorName': a['doctor_name'] as String? ?? 'your doctor',
                      'channelId': 'appointment_${a['id']}',
                    },
                  ),
                  onCancel: (a) => _cancelAppointment(a['id'].toString()),
                  onRefresh: _loadAppointments,
                ),
                _ListTab(
                  items: completed,
                  emptyText: 'No completed appointments yet.',
                  emptyIcon: Icons.check_circle_outline,
                  onJoin: null,
                  onCancel: null,
                  onRefresh: _loadAppointments,
                ),
                _ListTab(
                  items: cancelled,
                  emptyText: 'No cancelled appointments.',
                  emptyIcon: Icons.cancel_outlined,
                  onJoin: null,
                  onCancel: null,
                  onRefresh: _loadAppointments,
                ),
              ],
            ),
    );
  }
}

// ── List tab ──────────────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final IconData emptyIcon;
  final void Function(Map<String, dynamic> a)? onJoin;
  final void Function(Map<String, dynamic> a)? onCancel;
  final Future<void> Function()? onRefresh;

  const _ListTab({
    required this.items,
    required this.emptyText,
    required this.emptyIcon,
    required this.onJoin,
    required this.onCancel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(message: emptyText, icon: emptyIcon);
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: 2 columns for tablet/desktop (width > 600)
          final isWide = constraints.maxWidth > 600;

          if (isWide) {
            return _buildWideLayout();
          }
          return _buildNarrowLayout();
        },
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) =>
          _AppointmentCard(a: items[i], onJoin: onJoin, onCancel: onCancel),
    );
  }

  Widget _buildWideLayout() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          _AppointmentCard(a: items[i], onJoin: onJoin, onCancel: onCancel),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.titleLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Book an appointment to get started',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> a;
  final void Function(Map<String, dynamic>)? onJoin;
  final void Function(Map<String, dynamic>)? onCancel;

  const _AppointmentCard({
    required this.a,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = (a['status'] as String? ?? 'pending').toUpperCase();
    final statusColor = _getStatusColor(a['status'] as String?);
    final statusBgColor = _getStatusBackgroundColor(a['status'] as String?);

    final isPending = a['status'] == 'pending';
    final isConfirmed = a['status'] == 'confirmed';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Could navigate to appointment details
        },
        borderRadius: AppRadius.lgAll,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with doctor info and status
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: statusBgColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  children: [
                    // Doctor avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Doctor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['doctor_name'] as String? ?? 'Unknown Doctor',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: AppTypography.titleLarge,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            a['doctor_specialty'] as String? ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _StatusBadge(status: status, color: statusColor),
                  ],
                ),
              ),

              // Details section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time row
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: a['date'] as String? ?? '',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _InfoChip(
                          icon: Icons.access_time_outlined,
                          label: a['time'] as String? ?? '',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Reason
                    if ((a['reason'] as String?)?.isNotEmpty ?? false)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_outlined,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              a['reason'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: AppTypography.bodySmall,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.md),
                    // Action buttons
                    _buildActions(context, isPending, isConfirmed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isPending, bool isConfirmed) {
    if (onCancel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (isConfirmed)
          Expanded(
            child: _ActionButton(
              label: 'Message',
              icon: Icons.chat_bubble_outline,
              color: AppColors.primary,
              onPressed: () => context.push(
                '/messaging-chat',
                extra: {
                  'doctorName':
                      a['doctor_name'] as String? ?? 'Dr. Sarah Martinez',
                  'doctorSpecialty': a['doctor_specialty'] as String? ?? '',
                  'doctorId': a['doctor_id'] as String?,
                  'appointmentId': a['id']?.toString(),
                },
              ),
              isPrimary: false,
            ),
          ),
        if (isConfirmed) const SizedBox(width: AppSpacing.sm),
        if ((isPending || isConfirmed) && onCancel != null)
          Expanded(
            child: _ActionButton(
              label: 'Cancel',
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              onPressed: () => onCancel!(a),
              isPrimary: false,
            ),
          ),
        if (isPending || isConfirmed) const SizedBox(width: AppSpacing.sm),
        if (onJoin != null && isConfirmed)
          Expanded(
            child: _ActionButton(
              label: 'Join',
              icon: Icons.video_call_outlined,
              color: AppColors.info,
              onPressed: () => onJoin!(a),
              isPrimary: true,
            ),
          ),
        if (onJoin != null && isPending)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.mdAll,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Waiting',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
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

  Color _getStatusBackgroundColor(String? status) {
    switch (status) {
      case 'confirmed':
        return AppColors.successLight;
      case 'pending':
        return AppColors.warningLight;
      case 'completed':
        return AppColors.infoLight;
      case 'cancelled':
        return AppColors.errorLight;
      default:
        return AppColors.surfaceVariant;
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: AppTypography.labelSmall,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.labelMedium,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Material(
        color: color,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.mdAll,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 80,
              minHeight: 44, // Accessibility: minimum touch target
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTypography.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mdAll,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 80,
            minHeight: 44, // Accessibility: minimum touch target
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
