import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const _actions = [
    _QuickAction(
      icon: Icons.psychology_outlined,
      label: 'AI Symptom Check',
      color: Color(0xFF9333EA),
      path: '/symptom-check',
    ),
    _QuickAction(
      icon: Icons.calendar_today_outlined,
      label: 'Book Appointment',
      color: Color(0xFF2563EB),
      path: '/book-appointment',
    ),
    _QuickAction(
      icon: Icons.description_outlined,
      label: 'My Appointments',
      color: Color(0xFF059669),
      path: '/my-appointments',
    ),
    _QuickAction(
      icon: Icons.text_snippet_outlined,
      label: 'Medical History',
      color: Color(0xFFD97706),
      path: '/medical-history',
    ),
    _QuickAction(
      icon: Icons.inventory_2_outlined,
      label: 'Prescriptions',
      color: Color(0xFFDB2777),
      path: '/prescriptions',
    ),
    _QuickAction(
      icon: Icons.local_mall_outlined,
      label: 'Medical Store',
      color: Color(0xFF0891B2),
      path: '/medical-store',
    ),
    _QuickAction(
      icon: Icons.error_outline,
      label: 'Emergency',
      color: Color(0xFFDC2626),
      path: '/emergency',
      isEmergency: true,
    ),
    _QuickAction(
      icon: Icons.medication_outlined,
      label: 'My Medications',
      color: Color(0xFF7C3AED),
      path: '/my-medications',
    ),
  ];

  String _studentName = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadName();
    }
  }

  Future<void> _loadName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          final raw = data?['full_name']?.toString().trim() ?? '';
          if (raw.isNotEmpty) {
            _studentName = raw;
          } else {
            final email =
                Supabase.instance.client.auth.currentUser?.email ?? '';
            _studentName = email.isNotEmpty
                ? email.split('@').first
                : 'Student';
          }
        });
      }
    } catch (_) {}
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          _initialized = false;
          await _loadName();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient Header ────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B8CFF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 24),
                child: Row(
                  children: [
                    // ── Avatar ─────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // ── Greeting ───────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_studentName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Actions Label ────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // ── Quick Actions Grid ─────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _QuickActionTile(action: _actions[i]),
                  childCount: _actions.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Tile ─────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(action.path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: action.isEmergency
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: action.isEmergency
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Model ────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  final bool isEmergency;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
    this.isEmergency = false,
  });
}
