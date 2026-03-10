import 'dart:ui';

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
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        onRefresh: () async {
          _initialized = false;
          await _loadName();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Glassmorphism Header ────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles for depth
                    Positioned(
                      right: -30,
                      top: topPad - 10,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 28),
                      child: Row(
                        children: [
                          // ── Glassmorphic Avatar ────────────
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
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
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // ── Quick Actions Grid ─────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => SizedBox(
                    height: 80,
                    child: _QuickActionTile(action: _actions[i]),
                  ),
                  childCount: _actions.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Tile with Glassmorphism ───────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(action.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.75),
                border: Border.all(
                  color: action.isEmergency
                      ? const Color(0xFFFECACA)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          action.color.withValues(alpha: 0.15),
                          action.color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(action.icon, color: action.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.label,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: action.isEmergency
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0F172A),
                      ),
                    ),
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
