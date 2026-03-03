import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
      final data = await Supabase.instance.client
          .from('appointments')
          .select()
          .eq('student_id', userId!)
          .order('date', ascending: true);

      if (mounted) {
        setState(() => _appointments = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: const Color(0xFFDC2626),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filter(List<String> statuses) =>
      _appointments.where((a) => statuses.contains(a['status'])).toList();

  @override
  Widget build(BuildContext context) {
    final upcoming = _filter(['pending', 'confirmed']);
    final completed = _filter(['completed']);
    final cancelled = _filter(['cancelled']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Appointments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _ListTab(
                  items: upcoming,
                  emptyText: 'No upcoming appointments yet.',
                  onJoin: (a) => context.push('/consult'),
                  onCancel: (a) => _cancelAppointment(a['id'].toString()),
                ),
                _ListTab(
                  items: completed,
                  emptyText: 'No completed appointments yet.',
                  onJoin: null,
                  onCancel: null,
                ),
                _ListTab(
                  items: cancelled,
                  emptyText: 'No cancelled appointments.',
                  onJoin: null,
                  onCancel: null,
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
  final void Function(Map<String, dynamic> a)? onJoin;
  final void Function(Map<String, dynamic> a)? onCancel;

  const _ListTab({
    required this.items,
    required this.emptyText,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) =>
            _AppointmentCard(a: items[i], onJoin: onJoin, onCancel: onCancel),
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
    final statusColor = switch (a['status']) {
      'pending' => const Color(0xFFF59E0B),
      'confirmed' => const Color(0xFF2563EB),
      'completed' => const Color(0xFF059669),
      'cancelled' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };

    final isPending = a['status'] == 'pending';
    final isConfirmed = a['status'] == 'confirmed';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  a['doctor_name'] ?? 'Unknown Doctor',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _Chip(
                text: status,
                color: statusColor,
                bg: statusColor.withValues(alpha: 0.10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            a['doctor_specialty'] ?? '',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

          // Date + time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 4),
              Text(
                '${a['date'] ?? ''} · ${a['time'] ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reason
          Text(
            'Reason: ${a['reason'] ?? ''}',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (onCancel != null && (isPending || isConfirmed)) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onCancel!(a),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (onJoin != null && isConfirmed)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onJoin!(a),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Join'),
                  ),
                ),
              if (onJoin != null && isPending)
                Expanded(
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Waiting confirmation'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const _Chip({required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
